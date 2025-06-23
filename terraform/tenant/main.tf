terraform {
  required_providers {
    ionoscloud = {
      source  = "ionos-cloud/ionoscloud"
      version = ">= 6.4.10"
    }
  }
}

provider "ionoscloud" {
  token = var.ionos_token
}

variable "ionos_token" {
  type = string
}

variable "wordpress_tenants" {
  type    = list(string)
  default = ["tenant1"]
}

resource "ionoscloud_mariadb_cluster" "mariadb" {
  for_each        = toset(var.wordpress_tenants)
  display_name    = "mariadb-${each.key}"
  location        = "de/txl"
  mariadb_version = "10.6"
  instances       = 1
  cores           = 2
  ram             = 4
  storage_size    = 20

  credentials {
    username = "wpuser"
    password = "wp_password"
  }

  connections {
    datacenter_id = data.terraform_remote_state.infra.outputs.datacenter_id
    lan_id        = data.terraform_remote_state.infra.outputs.lan_id
    cidr          = "10.7.222.100/24"
  }
}

output "mariadb_connections" {
  value = {
    for tenant, cluster in ionoscloud_mariadb_cluster.mariadb :
    tenant => {
      host     = cluster.dns_name
      port     = 3306
      username = "root"
      password = "password" # Set via IONOS Cloud console
      database = "default"
    }
  }
  sensitive = true
} 