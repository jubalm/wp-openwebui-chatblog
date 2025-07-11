terraform {
  required_version = ">= 1.9.0, <= 1.10.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    ionoscloud = {
      source  = "ionos-cloud/ionoscloud"
      version = ">= 6.4.10"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
  }
  
  backend "s3" {
    key    = "platform/terraform.tfstate"
    bucket = "demo-vdc-backend-store"
    region = "eu-central-2"
    endpoints = {
      s3 = "https://s3-eu-central-2.ionoscloud.com"
    }
    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_region_validation      = true
    skip_s3_checksum            = true
  }
}





provider "ionoscloud" {
  token = var.ionos_token
}

locals {
  kubeconfig_decoded = yamldecode(data.terraform_remote_state.infra.outputs.kubeconfig)
}

provider "kubernetes" {
  host                   = local.kubeconfig_decoded.clusters[0].cluster.server
  token                  = local.kubeconfig_decoded.users[0].user.token
  cluster_ca_certificate = base64decode(local.kubeconfig_decoded.clusters[0].cluster["certificate-authority-data"])
}

provider "helm" {
  kubernetes = {
    host                   = local.kubeconfig_decoded.clusters[0].cluster.server
    token                  = local.kubeconfig_decoded.users[0].user.token
    cluster_ca_certificate = base64decode(local.kubeconfig_decoded.clusters[0].cluster["certificate-authority-data"])
  }
}

variable "ionos_token" {
  type = string
}



resource "ionoscloud_pg_cluster" "postgres" {
  display_name         = "postgres-cluster"
  location             = "de/txl"
  postgres_version     = "14"
  instances            = 1
  cores                = 4
  ram                  = 4096
  storage_size         = 10240
  storage_type         = "SSD"
  synchronization_mode = "ASYNCHRONOUS"

  credentials {
    username = var.pg_username
    password = var.pg_password
  }

  connections {
    datacenter_id = data.terraform_remote_state.infra.outputs.datacenter_id
    lan_id        = data.terraform_remote_state.infra.outputs.lan_id
    cidr          = "10.7.222.100/24"
  }

  lifecycle {
    ignore_changes = [credentials]
  }
}

resource "kubernetes_namespace" "admin_apps" {
  metadata {
    name = "admin-apps"
  }
}


resource "random_password" "authentik_secret_key" {
  length  = 32
  special = false
}


# NGINX Ingress - managed separately or imported if exists
# This resource is idempotent and can be safely reapplied
resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.10.1"
  timeout          = 600
  
  # Handle existing releases gracefully
  replace = true
  
  lifecycle {
    # Prevent accidental deletion of critical infrastructure
    prevent_destroy = true
    # Ignore changes that don't affect core functionality
    ignore_changes = [
      version,  # Allow version drift
      metadata
    ]
  }
}

resource "helm_release" "openwebui" {
  name              = "openwebui"
  namespace         = kubernetes_namespace.admin_apps.metadata[0].name
  repository        = "https://helm.openwebui.com/"
  chart             = "open-webui"
  version           = "6.22.0"
  create_namespace  = true
  dependency_update = true
  timeout           = 600

  values = [
    yamlencode({
      extraEnvFrom = [
        {
          secretRef = {
            name = kubernetes_secret.openwebui_env.metadata[0].name
          }
        }
      ]
    })
  ]
}

resource "helm_release" "authentik" {
  name              = "authentik"
  namespace         = kubernetes_namespace.admin_apps.metadata[0].name
  repository        = "https://charts.goauthentik.io"
  chart             = "authentik"
  version           = "2024.10.5"
  create_namespace  = false
  dependency_update = true
  timeout           = 600

  depends_on = [
    ionoscloud_pg_cluster.postgres,
    ionoscloud_pg_database.authentik,
    kubernetes_secret.authentik_env
  ]

  values = [
    yamlencode({
      authentik = {
        secret_key = random_password.authentik_secret_key.result
        postgresql = {
          host     = ionoscloud_pg_cluster.postgres.dns_name
          port     = 5432
          name     = ionoscloud_pg_database.authentik.name
          user     = var.pg_username
          password = var.pg_password
        }
        redis = {
          host = "authentik-redis-master.admin-apps.svc.cluster.local"
        }
      }
      postgresql = {
        enabled = false
      }
      redis = {
        enabled = true
      }
    })
  ]
}

resource "ionoscloud_pg_database" "authentik" {
  cluster_id = ionoscloud_pg_cluster.postgres.id
  name       = "authentik"
  owner      = var.pg_username
}

resource "kubernetes_secret" "authentik_env" {
  metadata {
    name      = "authentik-env-secrets"
    namespace = kubernetes_namespace.admin_apps.metadata[0].name
  }
  data = {
    # Authentik requires specific environment variable names
    AUTHENTIK_SECRET_KEY              = random_password.authentik_secret_key.result
    AUTHENTIK_POSTGRESQL__HOST        = ionoscloud_pg_cluster.postgres.dns_name
    AUTHENTIK_POSTGRESQL__USER        = var.pg_username
    AUTHENTIK_POSTGRESQL__PASSWORD    = var.pg_password
    AUTHENTIK_POSTGRESQL__NAME        = ionoscloud_pg_database.authentik.name
    AUTHENTIK_REDIS__HOST            = "authentik-new-redis-master.admin-apps.svc.cluster.local"
    AUTHENTIK_REDIS__PORT            = "6379"
    
    # Legacy keys for backward compatibility during transition
    secret_key        = random_password.authentik_secret_key.result
    postgres_host     = ionoscloud_pg_cluster.postgres.dns_name
    postgres_user     = var.pg_username
    postgres_password = var.pg_password
    postgres_name     = ionoscloud_pg_database.authentik.name
  }
}

resource "kubernetes_secret" "openwebui_env" {
  metadata {
    name      = "openwebui-env-secrets"
    namespace = kubernetes_namespace.admin_apps.metadata[0].name
  }
  data = {
    OPENAI_API_KEY      = var.openai_api_key
    OPENAI_API_BASE_URL = "https://openai.inference.de-txl.ionos.com/v1"
    
    # OAuth2 Configuration for Authentik SSO
    WEBUI_URL               = "http://openwebui.local"
    ENABLE_OAUTH_SIGNUP     = "true"
    OAUTH_CLIENT_ID         = "openwebui-client"
    OAUTH_CLIENT_SECRET     = "openwebui-secret-2025"
    OPENID_PROVIDER_URL     = "http://authentik.local/application/o/openwebui/.well-known/openid-configuration"
    OAUTH_PROVIDER_NAME     = "Authentik SSO"
    OAUTH_SCOPES           = "openid email profile"
    ENABLE_LOGIN_FORM      = "true"
  }
}

resource "kubernetes_deployment" "wordpress_oauth_pipeline" {
  # Ensure deployment is created after its dependencies
  depends_on = [
    kubernetes_namespace.admin_apps,
    kubernetes_secret.wordpress_oauth_env
  ]
  
  metadata {
    name      = "wordpress-oauth-pipeline"
    namespace = kubernetes_namespace.admin_apps.metadata[0].name
    labels = {
      app = "wordpress-oauth-pipeline"
    }
  }

  spec {
    replicas = 1
    
    strategy {
      type = "Recreate"  # This ensures old pod is terminated before new one is created
    }
    
    selector {
      match_labels = {
        app = "wordpress-oauth-pipeline"
      }
    }

    template {
      metadata {
        labels = {
          app = "wordpress-oauth-pipeline"
        }
      }

      spec {
        image_pull_secrets {
          name = kubernetes_secret.ionos_cr_secret.metadata[0].name
        }
        
        container {
          name  = "wordpress-oauth-pipeline"
          image = "wp-openwebui.cr.de-fra.ionos.com/jubalm/ionos/poc/wordpress-oauth-pipeline:latest"
          port {
            container_port = 9099
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.wordpress_oauth_env.metadata[0].name
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/app/data"
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 9099
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 9099
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.wordpress_oauth_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "wordpress_oauth_pipeline" {
  metadata {
    name      = "wordpress-oauth-pipeline"
    namespace = kubernetes_namespace.admin_apps.metadata[0].name
  }

  spec {
    selector = {
      app = "wordpress-oauth-pipeline"
    }

    port {
      port        = 9099
      target_port = 9099
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_persistent_volume_claim" "wordpress_oauth_data" {
  metadata {
    name      = "wordpress-oauth-data"
    namespace = kubernetes_namespace.admin_apps.metadata[0].name
    labels = {
      app = "wordpress-oauth-pipeline"
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = "ionos-enterprise-hdd"
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
  
  # Critical: Don't wait for binding with WaitForFirstConsumer storage classes
  wait_until_bound = false
  
  lifecycle {
    # Ignore changes to prevent recreation issues
    ignore_changes = [metadata.0.annotations]
  }
}

resource "kubernetes_secret" "wordpress_oauth_env" {
  metadata {
    name      = "wordpress-oauth-env-secrets"
    namespace = kubernetes_namespace.admin_apps.metadata[0].name
  }
  data = {
    WORDPRESS_ENCRYPTION_KEY = "sFR3c6QlC9BH1r1fR-1B1L0cJzlLqJrS_HqlBJBDlhE="  # Valid Fernet key
    AUTHENTIK_URL           = "http://authentik.local"
    AUTHENTIK_CLIENT_ID     = var.authentik_client_id
    AUTHENTIK_CLIENT_SECRET = var.authentik_client_secret
  }
}

resource "kubernetes_secret" "ionos_cr_secret" {
  metadata {
    name      = "ionos-cr-secret"
    namespace = kubernetes_namespace.admin_apps.metadata[0].name
  }
  
  type = "kubernetes.io/dockerconfigjson"
  
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "wp-openwebui.cr.de-fra.ionos.com" = {
          username = var.cr_username
          password = var.cr_password
          auth     = base64encode("${var.cr_username}:${var.cr_password}")
        }
      }
    })
  }
}

resource "random_password" "wordpress_encryption_key" {
  length  = 32
  special = true
  override_special = "-_"
}

# Ingress for WordPress OAuth2 Pipeline - TEMPORARILY DISABLED
# resource "kubernetes_ingress_v1" "wordpress_oauth_ingress" {
#   metadata {
#     name      = "wordpress-oauth-ingress"
#     namespace = kubernetes_namespace.admin_apps.metadata[0].name
#     annotations = {
#       "kubernetes.io/ingress.class" = "nginx"
#       "nginx.ingress.kubernetes.io/rewrite-target" = "/$1"
#     }
#   }
#
#   spec {
#     rule {
#       http {
#         path {
#           path = "/api/wordpress/(.*)"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = kubernetes_service.wordpress_oauth_pipeline.metadata[0].name
#               port {
#                 number = 9099
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }

variable "openai_api_key" {
  type      = string
  sensitive = true
}

variable "pg_username" {
  type    = string
  default = "authentikuser"
}

variable "pg_password" {
  type    = string
  default = "authentik_password"
}

variable "authentik_client_id" {
  type        = string
  description = "Authentik OAuth2 Client ID for WordPress integration"
}

variable "authentik_client_secret" {
  type        = string
  description = "Authentik OAuth2 Client Secret for WordPress integration"
  sensitive   = true
}

variable "cr_username" {
  type        = string
  description = "Container registry username"
  sensitive   = true
}

variable "cr_password" {
  type        = string
  description = "Container registry password"
  sensitive   = true
}

