terraform {
  required_providers {
    ionoscloud = {
      source  = "ionos-cloud/ionoscloud"
      version = ">= 6.4.10"
    }
  }

  backend "s3" {
    key    = "demo-vdc/terraform.tfstate"
    bucket = "demo-vdc-backend-store"
    region = "eu-central-2"

    endpoints = {
      s3 = "https://s3-eu-central-2.ionoscloud.com"
    }

    # workaround for S3 backend issues with IONOS Cloud
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

variable "s3_access_key" {
  type = string
}

variable "s3_secret_key" {
  type = string
}

# Create a datacenter first
resource "ionoscloud_datacenter" "main" {
  name        = "demo-datacenter"
  location    = "de/txl"
  description = "Demo datacenter for OpenWebUI"
}

resource "ionoscloud_lan" "db_lan" {
  datacenter_id = ionoscloud_datacenter.main.id
  name            = "db-lan"
  public          = false
}

resource "ionoscloud_k8s_cluster" "mks" {
  name        = "mks-cluster"
  k8s_version = "1.32.5"
  maintenance_window {
    day_of_the_week = "Monday"
    time            = "03:00:00"
  }
}

resource "ionoscloud_k8s_node_pool" "mks_pool" {
  k8s_cluster_id    = ionoscloud_k8s_cluster.mks.id
  name              = "mks-node-pool"
  node_count        = 2
  cpu_family        = "INTEL_SIERRAFOREST"
  ram_size          = 4096
  availability_zone = "AUTO"
  datacenter_id     = ionoscloud_datacenter.main.id
  k8s_version       = "1.32.5"
  cores_count       = 2
  storage_type      = "SSD"
  storage_size      = 20
}

# Use the correct MariaDB cluster resource
resource "ionoscloud_mariadb_cluster" "mariadb" {
  display_name    = "mariadb-cluster"
  location        = "de/txl"
  mariadb_version = "10.6"
  instances       = 1
  cores           = 2
  ram             = 4096 # Value must be in MB, and at least 4096
  storage_size    = 20

  credentials {
    username = "wpuser"
    password = "wp_password"
  }

  connections {
    datacenter_id = ionoscloud_datacenter.main.id
    lan_id        = ionoscloud_lan.db_lan.id
    cidr          = "10.0.0.0/24"
  }
}

# Use the correct PostgreSQL cluster resource
resource "ionoscloud_pg_cluster" "postgres" {
  display_name         = "postgres-cluster"
  location             = "de/txl"
  postgres_version     = "14"
  instances            = 1
  cores                = 2
  ram                  = 2048
  storage_size         = 2048
  storage_type         = "SSD"
  synchronization_mode = "ASYNCHRONOUS"

  credentials {
    username = "authentikuser"
    password = "authentik_password"
  }

  connections {
    datacenter_id = ionoscloud_datacenter.main.id
    lan_id        = ionoscloud_lan.db_lan.id
    cidr          = "10.0.1.0/24" # Use a different CIDR block
  }
}

# output "kubeconfig" {
#   value = ionoscloud_k8s_cluster.mks.kube_config
# }

output "mariadb_connection" {
  value = {
    host     = ionoscloud_mariadb_cluster.mariadb.dns_name
    port     = 3306
    username = "root"
    password = "password" # Note: You'll need to set this via the IONOS Cloud console
    database = "default"
  }
}

output "postgres_connection" {
  value = {
    host     = ionoscloud_pg_cluster.postgres.dns_name
    port     = 5432
    username = "postgres"
    password = "password" # Note: You'll need to set this via the IONOS Cloud console
    database = "postgres"
  }
}
