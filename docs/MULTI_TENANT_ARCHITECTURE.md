# Multi-Tenant Scaling Architecture

## 🏗️ Overview

The WordPress-OpenWebUI integration supports a comprehensive multi-tenant architecture that enables secure, scalable deployment for multiple organizations or teams while maintaining proper isolation and resource allocation.

## 🎯 Architecture Principles

### 1. Tenant Isolation
- **Namespace-based isolation** - Each tenant gets a dedicated Kubernetes namespace
- **Database isolation** - Separate MariaDB clusters per tenant
- **Network policies** - Controlled inter-tenant communication
- **Resource quotas** - CPU, memory, and storage limits per tenant

### 2. Shared Infrastructure
- **Single Kubernetes cluster** - Efficient resource utilization
- **Shared Authentik SSO** - Centralized authentication with tenant-specific OAuth2 apps
- **Shared OpenWebUI platform** - Multi-tenant content automation
- **Shared pipeline services** - OAuth2 pipeline with tenant isolation

### 3. Dynamic Provisioning
- **Automated tenant creation** - Terraform-based tenant provisioning
- **Self-service onboarding** - API-driven tenant registration
- **Resource scaling** - Dynamic resource allocation based on usage
- **Configuration management** - Tenant-specific settings and customizations

## 🏭 Current Implementation

### Tenant Structure
```
Kubernetes Cluster
├── admin-apps (namespace)
│   ├── Authentik SSO Server
│   ├── OpenWebUI Platform
│   └── Pipeline Services
├── tenant1 (namespace)
│   ├── WordPress Instance
│   ├── MariaDB Connection
│   └── Tenant-specific Secrets
├── tenant2 (namespace)
│   ├── WordPress Instance
│   ├── MariaDB Connection
│   └── Tenant-specific Secrets
└── tenantN (namespace)
    ├── WordPress Instance
    ├── MariaDB Connection
    └── Tenant-specific Secrets
```

### Resource Allocation
```yaml
# Per-tenant resources
WordPress Instance:
  CPU: 500m-1000m
  Memory: 512Mi-1Gi
  Storage: 5Gi-20Gi

MariaDB Cluster:
  Cores: 2
  RAM: 4GB
  Storage: 20GB

Network:
  Ingress: Dedicated subdomain
  LoadBalancer: Shared (host-based routing)
```

## 🔧 Tenant Configuration

### Current Terraform Variables
```hcl
variable "wordpress_tenants" {
  type = map(object({
    admin_user     = string
    admin_password = string
    admin_email    = string
  }))
  default = {
    "tenant1" = {
      admin_user     = "tenant1-admin"
      admin_password = "securepassword1"
      admin_email    = "admin@tenant1.com"
    }
  }
}
```

### Enhanced Tenant Configuration
```hcl
variable "wordpress_tenants" {
  type = map(object({
    # Basic tenant info
    display_name   = string
    admin_user     = string
    admin_password = string
    admin_email    = string
    
    # Resource allocation
    cpu_request    = string
    cpu_limit      = string
    memory_request = string
    memory_limit   = string
    storage_size   = string
    
    # Database configuration
    db_cores       = number
    db_ram         = number
    db_storage     = number
    
    # Feature flags
    features = object({
      content_automation = bool
      sso_enabled       = bool
      custom_plugins    = bool
      analytics_enabled = bool
    })
    
    # Custom domains
    custom_domains = list(string)
    
    # Billing tier
    tier = string # free, pro, enterprise
  }))
}
```

## 🚀 Enhanced Multi-Tenant Features

### 1. Tenant Management API

#### Create Tenant
```http
POST /api/v1/tenants
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "tenant_id": "acme-corp",
  "display_name": "ACME Corporation",
  "admin_email": "admin@acme.com",
  "tier": "pro",
  "features": {
    "content_automation": true,
    "sso_enabled": true,
    "custom_plugins": true,
    "analytics_enabled": true
  },
  "resources": {
    "cpu_limit": "2000m",
    "memory_limit": "2Gi",
    "storage_size": "50Gi",
    "db_cores": 4,
    "db_ram": 8,
    "db_storage": 100
  },
  "custom_domains": ["blog.acme.com", "docs.acme.com"]
}
```

#### List Tenants
```http
GET /api/v1/tenants
Authorization: Bearer {admin_token}
```

#### Get Tenant Details
```http
GET /api/v1/tenants/{tenant_id}
Authorization: Bearer {admin_token}
```

#### Update Tenant
```http
PUT /api/v1/tenants/{tenant_id}
Authorization: Bearer {admin_token}
```

#### Delete Tenant
```http
DELETE /api/v1/tenants/{tenant_id}
Authorization: Bearer {admin_token}
```

### 2. Tenant Isolation Features

#### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: tenant-isolation
  namespace: "${tenant_id}"
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: admin-apps
  - from:
    - namespaceSelector:
        matchLabels:
          name: "${tenant_id}"
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: admin-apps
  - to: []
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 3306
```

#### Resource Quotas
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-quota
  namespace: "${tenant_id}"
spec:
  hard:
    requests.cpu: "${cpu_request}"
    requests.memory: "${memory_request}"
    limits.cpu: "${cpu_limit}"
    limits.memory: "${memory_limit}"
    persistentvolumeclaims: "5"
    requests.storage: "${storage_size}"
    pods: "10"
    services: "5"
    secrets: "20"
    configmaps: "20"
```

### 3. Tenant-Specific OAuth2 Configuration

Each tenant gets dedicated OAuth2 applications in Authentik:

```python
# Tenant OAuth2 App Creation
authentik_apps = {
  f"wordpress-{tenant_id}": {
    "name": f"WordPress {tenant_display_name}",
    "client_id": f"wordpress-{tenant_id}",
    "client_secret": generate_secure_secret(),
    "redirect_uris": [
      f"http://wordpress-{tenant_id}.local/wp-admin/admin-ajax.php?action=openid_connect_generic",
      f"https://{custom_domain}/wp-admin/admin-ajax.php?action=openid_connect_generic"
    ]
  },
  f"openwebui-{tenant_id}": {
    "name": f"OpenWebUI {tenant_display_name}",
    "client_id": f"openwebui-{tenant_id}",
    "client_secret": generate_secure_secret(),
    "redirect_uris": [
      f"http://openwebui.local/oauth/oidc/callback?tenant={tenant_id}",
      f"https://openwebui.{custom_domain}/oauth/oidc/callback"
    ]
  }
}
```

### 4. Content Automation Per Tenant

#### Tenant-Scoped Workflows
```python
class TenantContentAutomation:
    def __init__(self, tenant_id: str):
        self.tenant_id = tenant_id
        self.wordpress_client = self._get_tenant_wordpress_client()
        self.settings = self._load_tenant_settings()
    
    async def create_workflow(self, user_id: str, workflow_data: Dict):
        # Ensure user belongs to tenant
        if not await self._validate_user_tenant_access(user_id):
            raise PermissionError("User not authorized for this tenant")
        
        # Apply tenant-specific content processing rules
        processed_content = await self._apply_tenant_processing_rules(
            workflow_data["content"]
        )
        
        # Create workflow with tenant isolation
        workflow = ContentWorkflow(
            id=str(uuid.uuid4()),
            tenant_id=self.tenant_id,
            user_id=user_id,
            **workflow_data
        )
        
        return await self._process_workflow(workflow)
```

#### Tenant Settings Management
```python
class TenantSettings:
    def __init__(self, tenant_id: str):
        self.tenant_id = tenant_id
    
    @property
    def content_automation_config(self) -> Dict:
        return {
            "auto_publish": self.get_setting("auto_publish", False),
            "content_types": self.get_setting("content_types", ["blog_post"]),
            "default_categories": self.get_setting("default_categories", ["Blog"]),
            "seo_optimization": self.get_setting("seo_optimization", True),
            "custom_templates": self.get_setting("custom_templates", {}),
            "workflow_approval": self.get_setting("workflow_approval", False)
        }
```

## 📊 Billing and Usage Tracking

### 1. Resource Metering
```python
class TenantMetering:
    def __init__(self, tenant_id: str):
        self.tenant_id = tenant_id
    
    async def collect_usage_metrics(self):
        return {
            "cpu_hours": await self._get_cpu_usage(),
            "memory_gb_hours": await self._get_memory_usage(),
            "storage_gb_hours": await self._get_storage_usage(),
            "api_requests": await self._get_api_requests(),
            "content_workflows": await self._get_workflow_count(),
            "database_queries": await self._get_db_queries(),
            "bandwidth_gb": await self._get_bandwidth_usage()
        }
    
    async def generate_billing_report(self, start_date: datetime, end_date: datetime):
        usage = await self.collect_usage_metrics()
        tier_config = await self._get_tenant_tier_config()
        
        return BillingReport(
            tenant_id=self.tenant_id,
            period=(start_date, end_date),
            usage=usage,
            costs=self._calculate_costs(usage, tier_config)
        )
```

### 2. Tier-Based Features
```yaml
tiers:
  free:
    limits:
      cpu: "500m"
      memory: "512Mi"
      storage: "5Gi"
      workflows_per_month: 100
      api_requests_per_day: 1000
    features:
      content_automation: true
      sso_enabled: false
      custom_plugins: false
      analytics_enabled: false
      support_level: "community"
  
  pro:
    limits:
      cpu: "2000m"
      memory: "2Gi"
      storage: "50Gi"
      workflows_per_month: 10000
      api_requests_per_day: 100000
    features:
      content_automation: true
      sso_enabled: true
      custom_plugins: true
      analytics_enabled: true
      support_level: "standard"
  
  enterprise:
    limits:
      cpu: "unlimited"
      memory: "unlimited"
      storage: "unlimited"
      workflows_per_month: "unlimited"
      api_requests_per_day: "unlimited"
    features:
      content_automation: true
      sso_enabled: true
      custom_plugins: true
      analytics_enabled: true
      support_level: "premium"
      custom_domains: true
      white_labeling: true
      dedicated_resources: true
```

## 🔐 Security Considerations

### 1. Tenant Data Isolation
- **Database-level isolation** - Separate MariaDB instances
- **Filesystem isolation** - Separate persistent volumes
- **Memory isolation** - Container-level memory limits
- **Network isolation** - NetworkPolicies preventing cross-tenant communication

### 2. Authentication & Authorization
- **Tenant-scoped OAuth2 apps** - Separate client credentials per tenant
- **Role-based access control** - Tenant admins, users, and viewers
- **API key management** - Tenant-specific API keys for automation
- **Audit logging** - Complete audit trail per tenant

### 3. Data Privacy
- **GDPR compliance** - Right to be forgotten, data portability
- **Data encryption** - At rest and in transit
- **Backup isolation** - Tenant-specific backup schedules and retention
- **Data residency** - Region-specific deployments when required

## 🚀 Deployment Strategy

### 1. Tenant Provisioning Pipeline
```yaml
# .github/workflows/tenant-provisioning.yml
name: Tenant Provisioning
on:
  workflow_dispatch:
    inputs:
      tenant_id:
        description: 'Tenant ID'
        required: true
      tier:
        description: 'Billing tier'
        required: true
        type: choice
        options:
        - free
        - pro
        - enterprise

jobs:
  provision-tenant:
    runs-on: ubuntu-latest
    steps:
    - name: Provision Infrastructure
      run: |
        cd terraform/tenant
        terraform plan -var="tenant_id=${{ inputs.tenant_id }}"
        terraform apply -auto-approve
    
    - name: Configure OAuth2
      run: |
        ./scripts/setup-tenant-oauth.sh ${{ inputs.tenant_id }}
    
    - name: Validate Deployment
      run: |
        ./scripts/test-tenant-deployment.sh ${{ inputs.tenant_id }}
```

### 2. Automated Scaling
```python
class TenantScaler:
    async def monitor_tenant_resources(self):
        for tenant in await self.get_active_tenants():
            usage = await self.get_tenant_resource_usage(tenant.id)
            
            if usage.cpu > 0.8 or usage.memory > 0.8:
                await self.scale_tenant_resources(tenant.id, "up")
            elif usage.cpu < 0.2 and usage.memory < 0.2:
                await self.scale_tenant_resources(tenant.id, "down")
    
    async def scale_tenant_resources(self, tenant_id: str, direction: str):
        current_config = await self.get_tenant_config(tenant_id)
        
        if direction == "up":
            new_config = self._increase_resources(current_config)
        else:
            new_config = self._decrease_resources(current_config)
        
        await self.apply_tenant_config(tenant_id, new_config)
        await self.notify_tenant_admin(tenant_id, f"Resources scaled {direction}")
```

## 📈 Monitoring and Observability

### 1. Tenant-Specific Dashboards
- **Resource utilization** - CPU, memory, storage per tenant
- **Application metrics** - WordPress performance, content automation stats
- **Business metrics** - Content published, user engagement, API usage
- **Cost tracking** - Resource costs and billing projections

### 2. Alerting
```yaml
# Tenant resource alerts
alerts:
  - alert: TenantHighCPUUsage
    expr: tenant_cpu_usage_percent > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage for tenant {{ $labels.tenant_id }}"
  
  - alert: TenantDiskSpaceLow
    expr: tenant_disk_usage_percent > 90
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Low disk space for tenant {{ $labels.tenant_id }}"
```

## 🎯 Future Enhancements

### 1. Advanced Multi-Tenancy Features
- **Tenant federation** - Cross-tenant collaboration
- **Tenant templates** - Pre-configured tenant setups
- **Tenant marketplace** - Plugin and theme marketplace
- **Tenant analytics** - Advanced usage analytics and insights

### 2. Enterprise Features
- **White-labeling** - Custom branding per tenant
- **Custom domains** - Tenant-specific domain management
- **Advanced security** - SOC2 compliance, advanced audit logs
- **Dedicated infrastructure** - Isolated clusters for enterprise tenants

### 3. Developer Experience
- **Tenant CLI** - Command-line tools for tenant management
- **SDK** - Multi-tenant development kit
- **Testing framework** - Automated tenant testing tools
- **Documentation** - Tenant-specific API documentation

---

**Generated with [Claude Code](https://claude.ai/code)**