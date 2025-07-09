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