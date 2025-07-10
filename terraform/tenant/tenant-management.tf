# Multi-Tenant Management Resources

# Generate secure passwords for database connections (only for MariaDB tenants)
resource "random_password" "db_password" {
  for_each = {
    for tenant_id, config in local.enhanced_tenants :
    tenant_id => config
    if config.database_type == "mariadb"
  }
  length   = 16
  special  = true
}

# Generate OAuth2 client secrets for each tenant
resource "random_password" "oauth_client_secret" {
  for_each = local.enhanced_tenants
  length   = 32
  special  = false
}

# Create MariaDB clusters only for tiers that require managed database
resource "ionoscloud_mariadb_cluster" "mariadb" {
  for_each        = {
    for tenant_id, config in local.enhanced_tenants :
    tenant_id => config
    if config.database_type == "mariadb"
  }
  display_name    = "mariadb-${each.key}"
  location        = each.value.region
  mariadb_version = "10.6"
  instances       = 1
  cores           = each.value.db_cores
  ram             = each.value.db_ram
  storage_size    = each.value.db_storage

  credentials {
    username = "wpuser"
    password = random_password.db_password[each.key].result
  }

  connections {
    datacenter_id = data.terraform_remote_state.infra.outputs.datacenter_id
    lan_id        = data.terraform_remote_state.infra.outputs.lan_id
    cidr          = "0.0.0.0/0"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Create tenant namespaces
resource "kubernetes_namespace" "wordpress_tenants" {
  for_each = local.enhanced_tenants
  
  metadata {
    name = each.key
    
    labels = {
      "tenant"                    = each.key
      "tier"                     = each.value.tier
      "content-automation"       = tostring(each.value.features.content_automation)
      "sso-enabled"              = tostring(each.value.features.sso_enabled)
      "managed-by"               = "terraform"
      "app.kubernetes.io/name"   = "wordpress-tenant"
      "app.kubernetes.io/part-of" = "wp-openwebui-platform"
    }
    
    annotations = {
      "tenant.wp-openwebui.io/display-name" = each.value.display_name
      "tenant.wp-openwebui.io/admin-email"  = each.value.admin_email
      "tenant.wp-openwebui.io/created-at"   = timestamp()
    }
  }
}

# Create resource quotas for tenant isolation
resource "kubernetes_resource_quota" "tenant_quota" {
  for_each = var.tenant_management.enable_resource_quotas ? local.enhanced_tenants : {}
  
  metadata {
    name      = "tenant-quota"
    namespace = kubernetes_namespace.wordpress_tenants[each.key].metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"               = each.value.cpu_request
      "requests.memory"            = each.value.memory_request
      "limits.cpu"                 = each.value.cpu_limit
      "limits.memory"              = each.value.memory_limit
      "persistentvolumeclaims"     = "5"
      "requests.storage"           = each.value.storage_size
      "pods"                       = "10"
      "services"                   = "5"
      "secrets"                    = "20"
      "configmaps"                 = "20"
      "count/ingresses.networking.k8s.io" = "5"
    }
  }
}

# Create network policies for tenant isolation
resource "kubernetes_network_policy" "tenant_isolation" {
  for_each = var.tenant_management.enable_network_policies ? local.enhanced_tenants : {}
  
  metadata {
    name      = "tenant-isolation"
    namespace = kubernetes_namespace.wordpress_tenants[each.key].metadata[0].name
  }

  spec {
    pod_selector {}
    
    policy_types = ["Ingress", "Egress"]
    
    # Allow ingress from admin-apps namespace (for load balancer)
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "admin-apps"
          }
        }
      }
    }
    
    # Allow ingress within the same tenant namespace
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = each.key
          }
        }
      }
    }
    
    # Allow egress to admin-apps namespace (for SSO, pipeline services)
    egress {
      to {
        namespace_selector {
          match_labels = {
            name = "admin-apps"
          }
        }
      }
    }
    
    # Allow egress for external services (internet, DNS)
    egress {
      # Allow HTTPS traffic to any external destination
      to {
        ip_block {
          cidr = "0.0.0.0/0"
          except = ["169.254.169.254/32"]  # Block metadata service
        }
      }
      ports {
        protocol = "TCP"
        port     = "443"
      }
    }
    
    # Allow HTTP traffic to any external destination  
    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
          except = ["169.254.169.254/32"]  # Block metadata service
        }
      }
      ports {
        protocol = "TCP"
        port     = "80"
      }
    }
    
    # Allow DNS resolution
    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
      ports {
        protocol = "UDP"
        port     = "53"
      }
      ports {
        protocol = "TCP"
        port     = "53"
      }
    }
  }
}

# Create registry secrets for each tenant
resource "kubernetes_secret" "registry_secret" {
  for_each = local.enhanced_tenants
  
  metadata {
    name      = "ionos-cr-secret"
    namespace = kubernetes_namespace.wordpress_tenants[each.key].metadata[0].name
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.cr_server}" = {
          auth = base64encode("${var.cr_username}:${var.cr_password}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}

# Create tenant-specific OAuth2 configuration secrets
resource "kubernetes_secret" "tenant_oauth_config" {
  for_each = local.enhanced_tenants
  
  metadata {
    name      = "oauth-config"
    namespace = kubernetes_namespace.wordpress_tenants[each.key].metadata[0].name
  }

  data = {
    AUTHENTIK_URL         = var.authentik_config.server_url
    OAUTH_CLIENT_ID       = "wordpress-${each.key}"
    OAUTH_CLIENT_SECRET   = random_password.oauth_client_secret[each.key].result
    OAUTH_REDIRECT_URI    = "http://wordpress-${each.key}.local/wp-admin/admin-ajax.php?action=openid_connect_generic"
    OAUTH_DISCOVERY_URL   = "${var.authentik_config.server_url}/application/o/wordpress-${each.key}/.well-known/openid-configuration"
    TENANT_ID             = each.key
    TENANT_DISPLAY_NAME   = each.value.display_name
    CONTENT_AUTOMATION_ENABLED = tostring(each.value.features.content_automation)
  }

  type = "Opaque"
}

# Create tenant configuration configmap
resource "kubernetes_config_map" "tenant_config" {
  for_each = local.enhanced_tenants
  
  metadata {
    name      = "tenant-config"
    namespace = kubernetes_namespace.wordpress_tenants[each.key].metadata[0].name
  }

  data = {
    "tenant.json" = jsonencode({
      tenant_id       = each.key
      display_name    = each.value.display_name
      tier           = each.value.tier
      region         = each.value.region
      features       = each.value.features
      settings       = each.value.settings
      custom_domains = each.value.custom_domains
      resource_limits = {
        cpu_request    = each.value.cpu_request
        cpu_limit      = each.value.cpu_limit
        memory_request = each.value.memory_request
        memory_limit   = each.value.memory_limit
        storage_size   = each.value.storage_size
      }
      database = {
        cores   = each.value.db_cores
        ram     = each.value.db_ram
        storage = each.value.db_storage
      }
    })
    
    "wordpress.conf" = templatefile("${path.module}/templates/wordpress.conf.tpl", {
      tenant_id    = each.key
      debug_mode   = each.value.settings.debug_mode
      auto_updates = each.value.settings.auto_updates_enabled
      timezone     = each.value.settings.timezone
      language     = each.value.settings.language
    })
  }
}

# Deploy WordPress using Helm with enhanced tenant configuration
resource "helm_release" "wordpress" {
  for_each          = local.enhanced_tenants
  name              = "wordpress-${each.key}"
  namespace         = kubernetes_namespace.wordpress_tenants[each.key].metadata[0].name
  chart             = "${path.module}/../../charts/wordpress"
  dependency_update = true
  timeout           = 600

  values = [
    yamlencode({
      fullnameOverride = "wordpress-${each.key}"
      
      image = {
        repository = "wp-openwebui.cr.de-fra.ionos.com/jubalm/ionos/poc/wordpress"
        tag        = var.wordpress_image_tag
      }
      
      imagePullSecrets = [
        { name = "ionos-cr-secret" }
      ]
      
      # Tenant-specific site configuration
      site = {
        url           = length(each.value.custom_domains) > 0 ? "https://${each.value.custom_domains[0]}" : "http://wordpress-${each.key}.local"
        title         = each.value.display_name
        adminUser     = each.value.admin_user
        adminPassword = each.value.admin_password
        adminEmail    = each.value.admin_email
        theme         = each.value.settings.theme
        language      = each.value.settings.language
        timezone      = each.value.settings.timezone
      }
      
      # Database configuration - conditional based on database type
      database = each.value.database_type == "sqlite" ? {
        type     = "sqlite"
        path     = "/var/www/html/wp-content/database/wordpress.sqlite"
        host     = ""
        user     = ""
        name     = ""
        password = ""
      } : {
        type     = "mariadb"
        host     = ionoscloud_mariadb_cluster.mariadb[each.key].dns_name
        user     = "wpuser"
        name     = "wordpress"
        password = random_password.db_password[each.key].result
        path     = ""
      }
      
      # Resource limits based on tier
      resources = {
        requests = {
          cpu    = each.value.cpu_request
          memory = each.value.memory_request
        }
        limits = {
          cpu    = each.value.cpu_limit
          memory = each.value.memory_limit
        }
      }
      
      # Ingress configuration
      ingress = {
        enabled = true
        className = "nginx"
        hosts = concat(
          [
            {
              host  = "wordpress-${each.key}.local"
              paths = [{ path = "/", pathType = "ImplementationSpecific" }]
            }
          ],
          [
            for domain in each.value.custom_domains : {
              host  = domain
              paths = [{ path = "/", pathType = "ImplementationSpecific" }]
            }
          ]
        )
        tls = length(each.value.custom_domains) > 0 ? [
          {
            secretName = "wordpress-${each.key}-tls"
            hosts      = each.value.custom_domains
          }
        ] : []
      }
      
      # Persistence configuration
      persistence = {
        enabled      = true
        storageClass = "ionos-enterprise-hdd"
        size         = each.value.storage_size
      }
      
      # Service account
      serviceAccount = {
        create = true
        name   = "wordpress-${each.key}"
        annotations = {
          "tenant.wp-openwebui.io/id" = each.key
        }
      }
      
      # Service configuration
      service = {
        port = 80
      }
      
      # OAuth2/SSO configuration
      authentik = {
        enabled      = each.value.features.sso_enabled
        url          = var.authentik_config.server_url
        clientId     = "wordpress-${each.key}"
        clientSecret = random_password.oauth_client_secret[each.key].result
      }
      
      # Feature flags
      features = each.value.features
      
      # Tenant metadata
      tenant = {
        id           = each.key
        displayName  = each.value.display_name
        tier         = each.value.tier
        adminEmail   = each.value.admin_email
      }
      
      # Environment-specific configuration
      env = [
        {
          name = "TENANT_ID"
          value = each.key
        },
        {
          name = "TENANT_TIER"
          value = each.value.tier
        },
        {
          name = "DATABASE_TYPE"
          value = each.value.database_type
        },
        {
          name = "CONTENT_AUTOMATION_ENABLED"
          value = tostring(each.value.features.content_automation)
        }
      ]
      
      # Volume mounts for tenant configuration
      extraVolumes = [
        {
          name = "tenant-config"
          configMap = {
            name = "tenant-config"
          }
        }
      ]
      
      extraVolumeMounts = [
        {
          name      = "tenant-config"
          mountPath = "/etc/tenant"
          readOnly  = true
        }
      ]
    })
  ]

  depends_on = [
    kubernetes_namespace.wordpress_tenants,
    kubernetes_secret.registry_secret,
    kubernetes_secret.tenant_oauth_config,
    kubernetes_config_map.tenant_config
  ]
}