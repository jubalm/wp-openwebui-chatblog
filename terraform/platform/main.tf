terraform {
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
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig_path
  }
}

variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

provider "ionoscloud" {
  token = var.ionos_token
}

variable "ionos_token" {
  type = string
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

data "ionoscloud_k8s_cluster" "mks" {
  name = ionoscloud_k8s_cluster.mks.name
}

resource "ionoscloud_k8s_node_pool" "mks_pool" {
  k8s_cluster_id    = ionoscloud_k8s_cluster.mks.id
  name              = "mks-node-pool"
  node_count        = 2
  cpu_family        = "INTEL_SIERRAFOREST"
  ram_size          = 4096
  availability_zone = "AUTO"
  datacenter_id     = data.terraform_remote_state.infra.outputs.datacenter_id
  k8s_version       = var.k8s_version
  cores_count       = 2
  storage_type      = "SSD"
  storage_size      = 20

  lans {
    id   = data.terraform_remote_state.infra.outputs.lan_id
    dhcp = true
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
  values            = [file("${path.module}/../../charts/authentik/my-values.yaml")]
  create_namespace  = true
  dependency_update = true
  timeout           = 600
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
  values            = [file("${path.module}/../../charts/openwebui/my-values.yaml")]
  create_namespace  = true
  dependency_update = true
  timeout           = 600
}

resource "ionoscloud_pg_database" "authentik" {
  cluster_id = ionoscloud_pg_cluster.postgres.id
  name       = "authentik"
  owner      = "authentikuser"
}

output "cluster_id" {
  value = ionoscloud_k8s_cluster.mks.id
}

output "kubeconfig" {
  value     = data.ionoscloud_k8s_cluster.mks.kube_config
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

output "postgres_connection" {
  value = {
    host     = ionoscloud_pg_cluster.postgres.dns_name
    port     = 5432
    username = var.pg_username
    password = var.pg_password
    database = "postgres"
  }
  sensitive = true
}