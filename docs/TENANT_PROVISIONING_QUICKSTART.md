# Tenant Provisioning Quick Start Guide

## 🚀 How to Use the Multi-Tenant System

The tenant provisioning system provides multiple ways to manage tenants. Here's how to get started:

## 1. CLI Tool (Easiest to Start)

The bash script provides a simple command-line interface:

### List existing tenants
```bash
./scripts/tenant-management.sh list
```

### Create a new tenant
```bash
./scripts/tenant-management.sh create acme-corp "ACME Corporation" admin@acme.com pro
```

### Get tenant details
```bash
./scripts/tenant-management.sh details acme-corp
```

### Scale a tenant to different tier
```bash
./scripts/tenant-management.sh scale acme-corp enterprise
```

### Test tenant functionality
```bash
./scripts/tenant-management.sh test acme-corp
```

### Delete a tenant
```bash
./scripts/tenant-management.sh delete acme-corp --confirm
```

## 2. Python API (For Automation)

Use the Python API for programmatic tenant management:

```python
from pipelines.tenant_manager import TenantManager, TenantTier

# Initialize manager
manager = TenantManager()

# Create a new tenant
tenant = await manager.create_tenant(
    tenant_id="startup-xyz",
    display_name="Startup XYZ",
    admin_email="admin@startup-xyz.com",
    tier=TenantTier.PRO
)

# List all tenants
tenants = await manager.list_tenants()

# Scale tenant
scaled_tenant = await manager.scale_tenant("startup-xyz", TenantTier.ENTERPRISE)

# Get usage metrics
usage = await manager.get_tenant_usage("startup-xyz")
```

## 3. Terraform Direct (For Infrastructure Teams)

Manually edit the Terraform configuration:

### Edit tenant configuration
```bash
# Edit terraform/tenant/main.tf and add to wordpress_tenants variable:
wordpress_tenants = {
  "tenant1" = {
    display_name   = "Demo Tenant 1"
    admin_user     = "tenant1-admin"
    admin_password = "securepassword1"
    admin_email    = "admin@tenant1.local"
    tier          = "free"
  }
  "new-company" = {
    display_name   = "New Company Inc"
    admin_user     = "new-company-admin"  
    admin_password = "securepassword123"
    admin_email    = "admin@newcompany.com"
    tier          = "pro"
  }
}
```

### Apply changes
```bash
cd terraform/tenant
terraform plan
terraform apply
```

## 4. Current System Setup

### Check what's already deployed
```bash
# Set kubeconfig
export KUBECONFIG=./kubeconfig.yaml

# See existing tenants
kubectl get namespaces -l "app.kubernetes.io/name=wordpress-tenant"

# Check current tenant1 status
kubectl get pods -n tenant1
kubectl get services -n tenant1
kubectl get ingress -n tenant1
```

### Access existing tenant1
```bash
# Get LoadBalancer IP
kubectl get service -n ingress-nginx ingress-nginx-controller

# Test access (replace with actual LoadBalancer IP)
curl -H "Host: wordpress-tenant1.local" http://85.215.220.121/
```

## 5. Tier Comparison

| Feature | Free | Pro | Enterprise |
|---------|------|-----|------------|
| CPU | 500m | 2000m | 4000m |
| Memory | 512Mi | 2Gi | 4Gi |
| Storage | 5Gi | 50Gi | 200Gi |
| Database | 1 core, 2GB RAM | 2 cores, 4GB RAM | 4 cores, 8GB RAM |
| SSO | ❌ | ✅ | ✅ |
| Custom Plugins | ❌ | ✅ | ✅ |
| Analytics | ❌ | ✅ | ✅ |
| Custom Domains | ❌ | ❌ | ✅ |
| Support | Community | Standard | Premium |

## 6. Example Workflows

### Create a tenant for a new customer
```bash
# 1. Create the tenant
./scripts/tenant-management.sh create customer-alpha "Customer Alpha Ltd" admin@customer-alpha.com pro

# 2. Verify it's working
./scripts/tenant-management.sh test customer-alpha

# 3. Check resource usage
./scripts/tenant-management.sh usage customer-alpha

# 4. Customer can access their site at:
# http://wordpress-customer-alpha.local (via LoadBalancer)
```

### Scale up a growing customer
```bash
# Customer needs more resources
./scripts/tenant-management.sh scale customer-alpha enterprise

# Verify the scaling worked
./scripts/tenant-management.sh details customer-alpha
```

### Migrate existing tenant1 to the new system
```bash
# Current tenant1 is already deployed, you can:

# 1. Check its current configuration
kubectl get configmap tenant-config -n tenant1 -o yaml

# 2. Test its functionality
./scripts/tenant-management.sh test tenant1

# 3. Scale it if needed
./scripts/tenant-management.sh scale tenant1 pro
```

## 7. Integration with Content Automation

Each tenant automatically gets:

- **Content automation enabled** (if tier supports it)
- **OAuth2 integration** with Authentik (if tier supports it)
- **Pipeline service access** for WordPress ↔ OpenWebUI integration

### Test content automation for a tenant
```bash
# 1. Ensure pipeline service is running
kubectl get pods -n admin-apps | grep wordpress-oauth-pipeline

# 2. Test tenant's WordPress API
curl -H "Host: wordpress-tenant1.local" http://85.215.220.121/wp-json/wp/v2/

# 3. Test content workflow creation (via pipeline service)
curl -X POST http://pipeline-service/api/content/workflows \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer tenant-token" \
  -d '{
    "title": "Test Post",
    "content": "<p>Test content</p>",
    "tenant_id": "tenant1"
  }'
```

## 8. Monitoring and Troubleshooting

### Check tenant health
```bash
# Overall tenant status
./scripts/tenant-management.sh list

# Detailed tenant info
./scripts/tenant-management.sh details <tenant-id>

# Test tenant functionality
./scripts/tenant-management.sh test <tenant-id>

# Check resource usage
./scripts/tenant-management.sh usage <tenant-id>
```

### Common issues and fixes
```bash
# Tenant pods not starting
kubectl describe pods -n <tenant-id>
kubectl logs -n <tenant-id> deployment/wordpress-<tenant-id>

# Database connection issues  
kubectl get secrets -n <tenant-id>
kubectl describe secret wordpress-db-config -n <tenant-id>

# Ingress/LoadBalancer issues
kubectl get ingress -n <tenant-id>
kubectl describe ingress -n <tenant-id>
```

## 9. Next Steps

1. **Start simple**: Use the CLI tool to create a test tenant
2. **Verify it works**: Test the tenant functionality
3. **Scale as needed**: Upgrade tiers based on usage
4. **Automate**: Integrate the Python API into your workflow
5. **Monitor**: Set up alerts and monitoring for tenant health

## 10. Getting Help

```bash
# Show CLI help
./scripts/tenant-management.sh help

# Check system prerequisites
./scripts/tenant-management.sh --help

# View tenant architecture documentation
cat docs/MULTI_TENANT_ARCHITECTURE.md
```

The tenant provisioning system is designed to be **simple to use** but **powerful for scale**. Start with the CLI tool and graduate to the API as your needs grow!