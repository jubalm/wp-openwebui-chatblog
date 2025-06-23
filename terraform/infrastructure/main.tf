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
  datacenter_id   = ionoscloud_datacenter.main.id
  name            = "db-lan"
  public          = false
}

output "datacenter_id" {
  value = ionoscloud_datacenter.main.id
}

output "lan_id" {
  value = ionoscloud_lan.db_lan.id
} 