terraform {
  required_providers {
    ionoscloud = {
      source  = "ionos-cloud/ionoscloud"
      version = ">= 6.4.10"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }

  backend "s3" {
    key    = "tenant/terraform.tfstate"
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
  type      = string
  sensitive = true
}

variable "wordpress_tenants" {
  type    = map(object({
    admin_user     = string
    admin_password = string
    admin_email    = string
  }))
  default = {
    "tenant1" = {
      admin_user     = "tenant1-admin"
      admin_password = "securepassword1"
      admin_email    = "admin@tenant1.com"
    }
  }
}

resource "random_password" "db_password" {
  for_each = var.wordpress_tenants
  length   = 16
  special  = true
}

resource "ionoscloud_mariadb_cluster" "mariadb" {
  for_each        = var.wordpress_tenants
  display_name    = "mariadb-${each.key}"
  location        = "de/txl"
  mariadb_version = "10.6"
  instances       = 1
  cores           = 2
  ram             = 4
  storage_size    = 20

  credentials {
    username = "wpuser"
    password = random_password.db_password[each.key].result
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

resource "kubernetes_namespace" "wordpress_tenants" {
  for_each = var.wordpress_tenants
  metadata {
    name = each.key
  }
}



resource "helm_release" "wordpress" {
  for_each          = var.wordpress_tenants
  name              = "wordpress-${each.key}"
  namespace         = kubernetes_namespace.wordpress_tenants[each.key].metadata[0].name
  chart             = "${path.module}/../../charts/wordpress"
  dependency_update = true
  timeout           = 600

  values = [
    yamlencode({
      fullnameOverride = "wordpress-${each.key}"
      image = {
        repository = "wp-openwebui.cr.de-fra.ionos.com/wp-openwebui/wordpress"
        tag        = "latest"
      }
      site = {
        url          = "http://wordpress-${each.key}.local"
        title        = "WordPress ${each.key}"
        adminUser    = each.value.admin_user
        adminPassword = each.value.admin_password
        adminEmail   = each.value.admin_email
      }
      database = {
        host     = ionoscloud_mariadb_cluster.mariadb[each.key].dns_name
        user     = "wpuser"
        name     = "wordpress"
        password = random_password.db_password[each.key].result # This will be used by the secret template
      }
      ingress = {
        enabled = true
        hosts = [
          {
            host  = "wordpress-${each.key}.local"
            paths = [{ path = "/", pathType = "ImplementationSpecific" }]
          }
        ]
      }
      persistence = {
        enabled = true
      }
    })
  ]

  
}

output "wordpress_urls" {
  value = {
    for tenant, release in helm_release.wordpress :
    tenant => "http://wordpress-${tenant}.local"
  }
}

output "mariadb_connections" {
  value = {
    for tenant, cluster in ionoscloud_mariadb_cluster.mariadb :
    tenant => {
      host     = cluster.dns_name
      port     = 3306
      username = "wpuser"
      database = "wordpress"
    }
  }
  sensitive = true
} 