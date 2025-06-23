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

output "postgres_connection" {
  value = {
    host     = ionoscloud_pg_cluster.postgres.dns_name
    port     = 5432
    username = "postgres"
    password = "password" # Set via IONOS Cloud console
    database = "postgres"
  }
  sensitive = true
} 