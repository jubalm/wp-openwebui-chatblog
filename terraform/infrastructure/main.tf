terraform {
  required_version = ">= 1.9.0, <= 1.12.2"
  required_providers {
    ionoscloud = {
      source  = "ionos-cloud/ionoscloud"
      version = ">= 6.4.10"
    }
  }
  backend "s3" {
    key    = "infrastructure/terraform.tfstate"
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

variable "ionos_token" {
  type = string
}

variable "datacenter_name" {
  type    = string
  default = "demo-datacenter"
}

variable "datacenter_location" {
  type    = string
  default = "de/txl"
}

resource "ionoscloud_datacenter" "main" {
  name        = var.datacenter_name
  location    = var.datacenter_location
  description = "Demo datacenter for OpenWebUI"
}

resource "ionoscloud_lan" "db_lan" {
  datacenter_id = ionoscloud_datacenter.main.id
  name          = "db-lan"
  public        = false
}

output "datacenter_id" {
  value = ionoscloud_datacenter.main.id
}

output "lan_id" {
  value = ionoscloud_lan.db_lan.id
}

variable "cluster_name" {
  type    = string
  default = "mks-cluster"
}

variable "k8s_version" {
  type    = string
  default = "1.32.5"
}

resource "ionoscloud_k8s_cluster" "mks" {
  name        = var.cluster_name
  k8s_version = var.k8s_version
  maintenance_window {
    day_of_the_week = "Monday"
    time            = "03:00:00Z"
  }
}

resource "ionoscloud_k8s_node_pool" "mks_pool_v2" {
  k8s_cluster_id    = ionoscloud_k8s_cluster.mks.id
  name              = "mks-node-pool-v2"
  node_count        = 3                    # Scaled to 3 nodes for HA
  cpu_family        = "INTEL_SIERRAFOREST"
  ram_size          = 8192                 # Increased to 8GB for better performance
  availability_zone = "AUTO"
  datacenter_id     = ionoscloud_datacenter.main.id
  k8s_version       = var.k8s_version
  cores_count       = 4                    # 4 cores per node
  storage_type      = "SSD"
  storage_size      = 100                  # Increased to 100GB to resolve disk pressure

  lifecycle {
    create_before_destroy = true
  }

  lans {
    id   = ionoscloud_lan.db_lan.id
    dhcp = true
  }
}

output "cluster_name" {
  value = ionoscloud_k8s_cluster.mks.name
}

data "ionoscloud_k8s_cluster" "mks" {
  name = ionoscloud_k8s_cluster.mks.name
}

output "kubeconfig" {
  value     = data.ionoscloud_k8s_cluster.mks.kube_config
  sensitive = true
}


