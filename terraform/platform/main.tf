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
}

output "cluster_id" {
  value = ionoscloud_k8s_cluster.mks.id
}

output "kubeconfig" {
  value     = data.ionoscloud_k8s_cluster.mks.kube_config
  sensitive = true
} 