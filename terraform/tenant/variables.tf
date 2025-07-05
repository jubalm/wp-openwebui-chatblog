# Enhanced Multi-Tenant Configuration Variables

variable "ionos_token" {
  type        = string
  sensitive   = true
  description = "IONOS Cloud API token"
}

variable "cr_server" {
  type        = string
  default     = "wp-openwebui.cr.de-fra.ionos.com"
  description = "Container registry server"
}

variable "cr_username" {
  type        = string
  sensitive   = true
  description = "Container registry username"
}

variable "cr_password" {
  type        = string
  sensitive   = true
  description = "Container registry password"
}

variable "wordpress_image_tag" {
  type        = string
  description = "The Docker image tag for WordPress. Defaults to 'latest' if not provided."
  default     = "latest"
}

# Enhanced tenant configuration
variable "wordpress_tenants" {
  type = map(object({
    # Basic tenant information
    display_name   = string
    admin_user     = string
    admin_password = string
    admin_email    = string
    
    # Resource allocation
    cpu_request    = optional(string, "250m")
    cpu_limit      = optional(string, "1000m")
    memory_request = optional(string, "256Mi")
    memory_limit   = optional(string, "1Gi")
    storage_size   = optional(string, "10Gi")
    
    # Database configuration
    db_cores       = optional(number, 2)
    db_ram         = optional(number, 4)
    db_storage     = optional(number, 20)
    
    # Feature flags
    features = optional(object({
      content_automation = optional(bool, true)
      sso_enabled       = optional(bool, true)
      custom_plugins    = optional(bool, false)
      analytics_enabled = optional(bool, false)
      backup_enabled    = optional(bool, true)
    }), {})
    
    # Custom domains (optional)
    custom_domains = optional(list(string), [])
    
    # Billing tier
    tier = optional(string, "free") # free, pro, enterprise
    
    # Region preference
    region = optional(string, "de/txl")
    
    # Tenant-specific settings
    settings = optional(object({
      timezone              = optional(string, "UTC")
      language              = optional(string, "en_US")
      theme                = optional(string, "twentytwentyfour")
      auto_updates_enabled = optional(bool, true)
      debug_mode           = optional(bool, false)
    }), {})
  }))
  
  description = "Configuration for WordPress tenants with enhanced multi-tenant features"
  
  # Default tenant configuration for demonstration
  default = {
    "tenant1" = {
      display_name   = "Demo Tenant 1"
      admin_user     = "tenant1-admin"
      admin_password = "securepassword1"
      admin_email    = "admin@tenant1.local"
      tier          = "free"
    }
  }
  
  validation {
    condition = alltrue([
      for tenant_id, config in var.wordpress_tenants :
      contains(["free", "pro", "enterprise"], config.tier)
    ])
    error_message = "Tenant tier must be one of: free, pro, enterprise."
  }
  
  validation {
    condition = alltrue([
      for tenant_id, config in var.wordpress_tenants :
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", tenant_id)) && length(tenant_id) <= 20
    ])
    error_message = "Tenant ID must be lowercase alphanumeric with hyphens, max 20 characters."
  }
}

# Tier-based resource configurations
locals {
  tier_configs = {
    free = {
      cpu_request    = "100m"
      cpu_limit      = "500m"
      memory_request = "128Mi"
      memory_limit   = "512Mi"
      storage_size   = "5Gi"
      db_cores       = 1
      db_ram         = 2
      db_storage     = 10
      features = {
        content_automation = true
        sso_enabled       = false
        custom_plugins    = false
        analytics_enabled = false
        backup_enabled    = false
      }
    }
    pro = {
      cpu_request    = "250m"
      cpu_limit      = "2000m"
      memory_request = "256Mi"
      memory_limit   = "2Gi"
      storage_size   = "50Gi"
      db_cores       = 2
      db_ram         = 4
      db_storage     = 50
      features = {
        content_automation = true
        sso_enabled       = true
        custom_plugins    = true
        analytics_enabled = true
        backup_enabled    = true
      }
    }
    enterprise = {
      cpu_request    = "500m"
      cpu_limit      = "4000m"
      memory_request = "512Mi"
      memory_limit   = "4Gi"
      storage_size   = "200Gi"
      db_cores       = 4
      db_ram         = 8
      db_storage     = 200
      features = {
        content_automation = true
        sso_enabled       = true
        custom_plugins    = true
        analytics_enabled = true
        backup_enabled    = true
      }
    }
  }
  
  # Merge tier defaults with explicit tenant configuration
  enhanced_tenants = {
    for tenant_id, config in var.wordpress_tenants :
    tenant_id => merge(
      local.tier_configs[config.tier],
      {
        display_name   = config.display_name
        admin_user     = config.admin_user
        admin_password = config.admin_password
        admin_email    = config.admin_email
        tier          = config.tier
        custom_domains = config.custom_domains
        region        = config.region
        settings      = config.settings
      },
      # Override with explicit resource settings if provided
      {
        cpu_request    = config.cpu_request != null ? config.cpu_request : local.tier_configs[config.tier].cpu_request
        cpu_limit      = config.cpu_limit != null ? config.cpu_limit : local.tier_configs[config.tier].cpu_limit
        memory_request = config.memory_request != null ? config.memory_request : local.tier_configs[config.tier].memory_request
        memory_limit   = config.memory_limit != null ? config.memory_limit : local.tier_configs[config.tier].memory_limit
        storage_size   = config.storage_size != null ? config.storage_size : local.tier_configs[config.tier].storage_size
        db_cores       = config.db_cores != null ? config.db_cores : local.tier_configs[config.tier].db_cores
        db_ram         = config.db_ram != null ? config.db_ram : local.tier_configs[config.tier].db_ram
        db_storage     = config.db_storage != null ? config.db_storage : local.tier_configs[config.tier].db_storage
        features       = merge(local.tier_configs[config.tier].features, config.features)
      }
    )
  }
}

# Global tenant management settings
variable "tenant_management" {
  type = object({
    enable_auto_scaling     = optional(bool, true)
    enable_resource_quotas  = optional(bool, true)
    enable_network_policies = optional(bool, true)
    backup_schedule        = optional(string, "0 2 * * *") # Daily at 2 AM
    monitoring_enabled     = optional(bool, true)
    log_retention_days     = optional(number, 30)
  })
  
  description = "Global tenant management configuration"
  default     = {}
}

# Authentik OAuth2 configuration
variable "authentik_config" {
  type = object({
    server_url    = optional(string, "http://authentik.admin-apps.svc.cluster.local:9000")
    admin_token   = optional(string, "")
    auto_create_apps = optional(bool, true)
  })
  
  description = "Authentik SSO configuration for tenant OAuth2 apps"
  default     = {}
}

# Monitoring and alerting configuration
variable "monitoring_config" {
  type = object({
    prometheus_enabled = optional(bool, true)
    grafana_enabled   = optional(bool, true)
    alertmanager_enabled = optional(bool, true)
    slack_webhook_url = optional(string, "")
    email_alerts_to   = optional(list(string), [])
  })
  
  description = "Monitoring and alerting configuration"
  default     = {}
}