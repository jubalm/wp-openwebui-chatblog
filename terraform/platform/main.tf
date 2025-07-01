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
    username = "authentikuser"
    password = "authentik_password"
  }

  connections {
    datacenter_id = data.terraform_remote_state.infra.outputs.datacenter_id
    lan_id        = data.terraform_remote_state.infra.outputs.lan_id
    cidr          = "10.7.222.222/24"
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

resource "helm_release" "authentik" {
  name              = "authentik"
  namespace         = kubernetes_namespace.admin_apps.metadata[0].name
  repository        = "https://charts.goauthentik.io/"
  chart             = "authentik"
  version           = "2024.6.0"
  create_namespace  = true
  dependency_update = true
  timeout           = 600

  values = [
    yamlencode({
      authentik = {
        secret_key = random_password.authentik_secret_key.result
      }
      postgresql = {
        enabled = false
      }
      envFrom = [
        {
          secretRef = {
            name = kubernetes_secret.authentik_env.metadata[0].name
          }
        }
      ]
    })
  ]
}

resource "random_password" "authentik_secret_key" {
  length  = 32
  special = false
}

resource "kubernetes_ingress_v1" "authentik_ingress" {
  metadata {
    name      = "authentik-ingress"
    namespace = kubernetes_namespace.admin_apps.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "authentik"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.10.1"
  # You can add custom values here if needed
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
      envFrom = [
        {
          secretRef = {
            name = kubernetes_secret.openwebui_env.metadata[0].name
          }
        }
      ]
    })
  ]
}

resource "ionoscloud_pg_database" "authentik" {
  cluster_id = ionoscloud_pg_cluster.postgres.id
  name       = "authentik"
  owner      = "authentikuser"
}

resource "kubernetes_secret" "authentik_env" {
  metadata {
    name      = "authentik-env-secrets"
    namespace = kubernetes_namespace.admin_apps.metadata[0].name
  }
  data = {
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
    OPENAI_API_BASE_URL = "https://api.ionos.com/llm/v1"
  }
}

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

