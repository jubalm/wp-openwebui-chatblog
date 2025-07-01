data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "demo-vdc-backend-store"
    key    = "infrastructure/terraform.tfstate"
    region = "eu-central-2"
    endpoints = {
      s3 = "https://s3-eu-central-2.ionoscloud.com"
    }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_region_validation      = true
    skip_s3_checksum            = true
  }
}

data "terraform_remote_state" "platform" {
  backend = "s3"
  config = {
    bucket = "demo-vdc-backend-store"
    key    = "platform/terraform.tfstate"
    region = "eu-central-2"
    endpoints = {
      s3 = "https://s3-eu-central-2.ionoscloud.com"
    }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_region_validation      = true
    skip_s3_checksum            = true
  }
} 