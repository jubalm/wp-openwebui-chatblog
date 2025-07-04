# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an IONOS Cloud-based Platform-as-a-Service (PaaS) project designed to deploy a multi-tenant WordPress environment with AI content generation capabilities via OpenWebUI, using centralized SSO through Authentik. The entire infrastructure is managed with Terraform and automated through GitHub Actions.

**Note**: For current deployment status and active issues, see `CLAUDE.md`.

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

**Primary Method**: Use `ionosctl` to get current kubeconfig:
```bash
# Get current kubeconfig (replace with actual cluster ID)
ionosctl k8s kubeconfig get --cluster-id <cluster-id>
```

**Alternative**: If kubeconfig file exists at project root:
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
- **WordPress-OpenWebUI Connector Plugin** (auto-installed at `docker/wordpress/plugins/wordpress-openwebui-connector/`)

### WordPress-OpenWebUI Integration Design

**Intended Architecture**:
- **Pipeline Service**: FastAPI microservice (`pipelines/`) handling OAuth2 flows and encrypted credential storage
- **WordPress Plugin**: Complete admin interface with OAuth2 client (auto-installed in WordPress containers)
- **Security**: AES-256 encrypted Application Password storage, server-to-server OAuth2 via Authentik

**Key Implementation Files**:
- `pipelines/wordpress_oauth.py` - OAuth2 server and API endpoints
- `pipelines/wordpress_client.py` - WordPress REST API client
- `docker/wordpress/plugins/wordpress-openwebui-connector/` - WordPress plugin
- `.github/workflows/build-and-push-wordpress.yml` - Builds both WordPress and Pipeline images
- `terraform/platform/main.tf` - Pipeline service Kubernetes resources

**Intended Usage Flow**: 
1. WordPress admin configures OAuth2 settings in Settings → OpenWebUI Connector
2. OAuth2 flow connects WordPress to OpenWebUI via Authentik SSO
3. Application Password securely stored and used for WordPress API calls
4. OpenWebUI can create/update WordPress posts via secure API

**Note**: For current integration status, see `CLAUDE.md`.

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

### Deployment Patterns Learned

- **Authentik requires PostgreSQL**: Cannot use Redis alone - needs PostgreSQL cluster
- **For PoC without SSO**: Scale Authentik deployments to 0 replicas to avoid restart loops
- **WordPress database**: Often works better than initial diagnostics suggest
- **Ingress configuration**: May already be working even when not obvious
- **System stability**: IONOS infrastructure layer is very reliable
- **Documentation vs Reality**: Always verify actual service status before assuming failures

## Troubleshooting Knowledge Base

### Database Connection Issues

**Problem**: WordPress shows "Database not ready, waiting..." continuously
**Root Cause**: Password mismatch between Terraform-generated MariaDB credentials and Kubernetes secrets

**Diagnosis Steps**:
1. Test network connectivity: `kubectl exec <pod> -- ping <mariadb-host>`
2. Test port connectivity: `kubectl exec <pod> -- curl -v telnet://<mariadb-host>:3306`
3. Check if MariaDB handshake is received (indicates network is OK)
4. Verify password in Kubernetes secret: `kubectl get secret <secret-name> -o yaml`

**Solution**:
- Generate new password: `openssl rand -base64 16`
- Update Kubernetes secret: `kubectl patch secret <secret-name> -p '{"data":{"password":"<base64-encoded-password>"}}'`
- Recreate MariaDB cluster with new password (IONOS clusters are immutable for credentials)
- Update WordPress deployment to use new database host

**Key Insights**:
- IONOS MariaDB clusters don't expose passwords via `ionosctl`
- Cannot update passwords on existing clusters - must recreate
- Always ensure password synchronization between Terraform and Helm layers
- WordPress database wait messages are generic - test connectivity separately

### IONOS MariaDB Cluster Management

**Cluster Creation Time**: 5-10 minutes (shows `CREATING` state)
**Password Management**: Immutable - cannot change after creation
**Network Access**: Use CIDR ranges like `10.7.222.100/24`, not `0.0.0.0/0`
**CLI Commands**:
- List clusters: `ionosctl dbaas mariadb cluster list`
- Get cluster details: `ionosctl dbaas mariadb cluster get --cluster-id <id>`
- Create cluster: `ionosctl dbaas mariadb cluster create --name <name> --user <user> --password <password> --datacenter-id <dc-id> --lan-id <lan-id> --cidr <cidr>`

### Kubernetes Secret Management

**Update existing secret**: `kubectl patch secret <name> -p '{"data":{"key":"<base64-value>"}}' --type='merge'`
**Base64 encoding**: `echo -n "password" | base64`
**Base64 decoding**: `echo "encoded" | base64 -d`

**Important**: Pods need restart to pick up secret changes unless they're watching for updates.

### WordPress Container Debugging

**Available tools in WordPress containers**:
- `ping` - network connectivity
- `curl` - HTTP/TCP connectivity testing
- `mysql` - if MySQL client is installed

**Missing tools**:
- `nslookup` - use `ping` instead for DNS resolution
- Advanced network tools - use `curl` for port testing

**Log patterns**:
- `Database not ready, waiting...` - Generic database connectivity issue
- `ERROR 1045 (28000): Access denied` - Authentication failure
- `Can't connect to MySQL server` - Network connectivity issue

### Authentik Deployment Issues

**Problem**: Authentik server in restart loop with PostgreSQL connection errors
**Root Cause**: Authentik expects PostgreSQL but only Redis is available

**Diagnosis Steps**:
1. Check deployment status: `kubectl get deployment -n admin-apps | grep authentik`
2. Check logs: `kubectl logs -n admin-apps [authentik-server-pod] --tail=20`
3. Look for: `PostgreSQL connection failed, retrying...`

**Solutions**:
- **For PoC without SSO**: Scale to 0 replicas: `kubectl scale deployment authentik-server -n admin-apps --replicas=0`
- **For full SSO**: Deploy PostgreSQL cluster in Terraform infrastructure layer
- **Configuration check**: Verify `AUTHENTIK_POSTGRESQL__ENABLED` environment variable

**Key Insights**:
- Authentik cannot run with Redis alone - requires PostgreSQL for metadata
- Setting `AUTHENTIK_POSTGRESQL__ENABLED=false` doesn't switch to Redis-only mode
- Scaling to 0 replicas is safer than deleting deployments for temporary PoC
- Worker can also be scaled down: `kubectl scale deployment authentik-worker -n admin-apps --replicas=0`
