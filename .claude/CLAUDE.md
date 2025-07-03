# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an IONOS Cloud-based Platform-as-a-Service (PaaS) project that deploys a multi-tenant WordPress environment with AI content generation capabilities via OpenWebUI, using centralized SSO through Authentik. The entire infrastructure is managed with Terraform and automated through GitHub Actions.

## Key Commands

### Terraform Commands

When working with Terraform in this project:

1. **Always source the shell environment first:**
   ```bash
   source .shellrc
   ```

2. **Use `-chdir` flag for all Terraform commands:**
   ```bash
   # Infrastructure layer
   terraform -chdir=terraform/infrastructure init
   terraform -chdir=terraform/infrastructure plan
   terraform -chdir=terraform/infrastructure apply

   # Platform layer
   terraform -chdir=terraform/platform init
   terraform -chdir=terraform/platform plan
   terraform -chdir=terraform/platform apply

   # Tenant layer
   terraform -chdir=terraform/tenant init
   terraform -chdir=terraform/tenant plan
   terraform -chdir=terraform/tenant apply
   ```

### Kubernetes Access

A kubeconfig file is maintained at the project root: `kubeconfig.yaml`

To use this kubeconfig:
```bash
export KUBECONFIG=./kubeconfig.yaml
kubectl get nodes
```

Or use it directly with kubectl commands:
```bash
kubectl --kubeconfig=./kubeconfig.yaml get pods -A
```

### Docker Build Commands

Build the custom WordPress image:
```bash
docker build -t wordpress-custom:latest docker/wordpress/
```

### Deployment

Deployment is fully automated via GitHub Actions workflows:
- **Build WordPress Image**: `.github/workflows/build-and-push-wordpress.yml`
- **Deploy Infrastructure**: `.github/workflows/deploy.yml`

Manual deployment follows this sequence:
1. Infrastructure layer (MKS cluster, databases, S3 buckets)
2. Platform layer (Authentik, OpenWebUI, ingress)
3. Tenant layer (WordPress instances)

## Architecture Overview

### Three-Layer Terraform Structure

1. **Infrastructure Layer** (`terraform/infrastructure/`)
   - IONOS Managed Kubernetes (MKS) cluster
   - IONOS Managed PostgreSQL (for Authentik)
   - IONOS Managed MariaDB clusters (for WordPress tenants)
   - IONOS S3-compatible object storage (for Terraform state)
   - Outputs: kubeconfig, database connection details

2. **Platform Layer** (`terraform/platform/`)
   - Helm deployments for shared services
   - Authentik (identity provider)
   - OpenWebUI (AI interface)
   - NGINX Ingress Controller
   - Kubernetes secrets for service configurations

3. **Tenant Layer** (`terraform/tenant/`)
   - WordPress deployments (one per tenant)
   - Tenant-specific configurations
   - MCP (Model Context Protocol) integration

### Kubernetes Namespace Organization

- `admin-apps`: Shared platform services (Authentik, OpenWebUI)
- `tenant-<name>`: Isolated namespace for each WordPress tenant
- `ingress-nginx`: Ingress controller namespace

### Key Integration Points

1. **SSO Flow**: Authentik provides OIDC authentication for both WordPress and OpenWebUI
2. **MCP Integration**: OpenWebUI communicates with WordPress via MCP API endpoints
3. **LLM Access**: OpenWebUI connects to IONOS AI Platform (OpenAI-compatible endpoint)
4. **Database Connections**: Each service connects to its managed database via Kubernetes secrets

### Custom WordPress Components

The project includes a custom WordPress Docker image with:
- WordPress MCP plugin v0.2.2
- OpenID Connect Generic Client (for SSO)
- Custom integration plugin for OpenWebUI setup (in development)

### Secret Management

All sensitive data is managed through:
- GitHub Actions secrets (for CI/CD)
- Kubernetes secrets (for runtime configuration)
- Terraform outputs are used to populate Kubernetes secrets automatically

## Development Workflow

1. Make infrastructure changes in appropriate Terraform layer
2. Test locally with `terraform plan`
3. Push to trigger GitHub Actions deployment
4. Platform deployments are sequential: infrastructure → platform → tenant

## Important Notes

- Always use absolute paths in Kubernetes manifests
- Service discovery uses Kubernetes DNS: `service.namespace.svc.cluster.local`
- External access is via IP-based ingress (no custom domains in PoC)
- IONOS region: `de/txl`
- No testing framework or linting tools are currently configured
- Focus on minimal viable configurations for PoC deployment