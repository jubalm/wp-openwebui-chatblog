# Scripts Documentation

This directory contains management and utility scripts for the WordPress-OpenWebUI integration platform.

## Overview

The scripts in this directory provide essential functionality for:
- Multi-tenant WordPress management
- Local development and building
- Platform validation and testing

## Available Scripts

### 1. tenant-management.sh
**Purpose**: Comprehensive multi-tenant management system for WordPress instances

**Features**:
- Create, delete, and scale WordPress tenants
- Terraform integration for infrastructure provisioning
- Resource quota management based on tiers (free, pro, enterprise)
- Tenant health testing and monitoring

**Usage**:
```bash
# List all tenants
./scripts/tenant-management.sh list

# Create a new tenant
./scripts/tenant-management.sh create <tenant_id> <display_name> <admin_email> [tier]
./scripts/tenant-management.sh create acme-corp "ACME Corporation" admin@acme.com pro

# Get tenant details
./scripts/tenant-management.sh details <tenant_id>

# Scale tenant to different tier
./scripts/tenant-management.sh scale <tenant_id> <new_tier>

# Test tenant functionality
./scripts/tenant-management.sh test <tenant_id>

# Delete tenant (requires confirmation)
./scripts/tenant-management.sh delete <tenant_id> --confirm

# Show resource usage
./scripts/tenant-management.sh usage <tenant_id>
```

**Prerequisites**:
- `terraform`, `kubectl`, `jq`, `yq` installed
- Valid kubeconfig at `./kubeconfig.yaml`
- Terraform state access

### 2. build-and-deploy-local.sh
**Purpose**: Local development script for building Docker images

**⚠️ Note**: This script is for LOCAL DEVELOPMENT ONLY. For production deployments, use GitHub Actions workflows.

**Features**:
- Builds WordPress Docker image with OpenWebUI connector plugin
- Builds Pipeline service Docker image
- Packages WordPress plugin for distribution
- Provides deployment instructions

**Usage**:
```bash
# Build images locally
./scripts/build-and-deploy-local.sh

# Configure registry (edit script)
DOCKER_REGISTRY="localhost:5000"  # Update with your registry
```

**Prerequisites**:
- Docker installed and running
- Access to container registry (if pushing images)

## Test Scripts

Additional test scripts are available in `tests/scripts/`:

### Integration Testing
- **test-integration.sh**: Comprehensive platform health checks
- **test-sso-integration.sh**: OAuth2/SSO validation
- **test-content-automation.sh**: Content pipeline testing
- **demo-tenant-system.sh**: Interactive platform demonstration

See [Test Scripts Documentation](../tests/scripts/README.md) for details.

## Environment Variables

The scripts support the following environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `KUBECONFIG` | `./kubeconfig.yaml` | Path to Kubernetes config |
| `CLUSTER_ID` | `354372a8-cdfc-4c4c-814c-37effe9bf8a2` | IONOS cluster ID |
| `LOADBALANCER_IP` | `85.215.220.121` | External LoadBalancer IP |
| `IONOS_TOKEN` | Required for some operations | IONOS API token |

## Common Tasks

### Setting up for first use
```bash
# Get cluster access
ionosctl k8s kubeconfig get --cluster-id 354372a8-cdfc-4c4c-814c-37effe9bf8a2
export KUBECONFIG=./kubeconfig.yaml

# Verify connection
kubectl get nodes
```

### Creating a production-ready tenant
```bash
# 1. Create the tenant
./scripts/tenant-management.sh create production-app "Production Application" admin@company.com enterprise

# 2. Wait for provisioning (2-3 minutes)
./scripts/tenant-management.sh test production-app

# 3. Access the tenant
# Add to /etc/hosts: 85.215.220.121 wordpress-production-app.local
# Browse to: http://wordpress-production-app.local
```

### Monitoring tenant resources
```bash
# Check resource usage
./scripts/tenant-management.sh usage tenant-name

# Get detailed information
./scripts/tenant-management.sh details tenant-name
```

## Tier Specifications

| Feature | Free | Pro | Enterprise |
|---------|------|-----|------------|
| CPU Limit | 500m | 2000m | 4000m |
| Memory Limit | 512Mi | 2Gi | 4Gi |
| Storage | 5Gi | 50Gi | 200Gi |
| Database | 1c/2GB | 2c/4GB | 4c/8GB |
| SSO | ❌ | ✅ | ✅ |
| Custom Plugins | ❌ | ✅ | ✅ |
| Custom Domains | ❌ | ❌ | ✅ |

## Troubleshooting

### Script not found
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

### Kubeconfig issues
```bash
# Download fresh kubeconfig
ionosctl k8s kubeconfig get --cluster-id 354372a8-cdfc-4c4c-814c-37effe9bf8a2
```

### Terraform state issues
```bash
# Initialize terraform in tenant directory
cd terraform/tenant
terraform init
```

## Related Documentation

- [Developer Quickstart](../docs/DEVELOPER_QUICKSTART.md)
- [Multi-Tenant Architecture](../docs/MULTI_TENANT_ARCHITECTURE.md)
- [Tenant Provisioning Guide](../docs/TENANT_PROVISIONING_QUICKSTART.md)
- [Platform Documentation](../README.md)

## Contributing

When adding new scripts:
1. Follow the existing naming convention
2. Add comprehensive help/usage information
3. Update this README with documentation
4. Use consistent error handling and logging
5. Support common environment variables