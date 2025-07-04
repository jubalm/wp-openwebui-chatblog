# IONOS WordPress-OpenWebUI Project - PoC FULLY OPERATIONAL! 🎉

## Current Deployment Status (July 4, 2025)

**Cluster**: `354372a8-cdfc-4c4c-814c-37effe9bf8a2` | **LoadBalancer**: `85.215.220.121`

### ✅ Working Services
- **WordPress**: `wordpress-tenant1.local` → `85.215.220.121` (fully functional)
- **OpenWebUI**: `openwebui.local` → `85.215.220.121` (fully functional)  
- **MariaDB**: `ma-d8nn61870q23eimk.mariadb.de-txl.ionos.com` (connected)
- **NGINX Ingress**: External LoadBalancer operational
- **Infrastructure**: IONOS MKS cluster stable

### ⚠️ Disabled for PoC
- **Authentik SSO**: Scaled to 0 (PostgreSQL dependency)
- **OAuth2 Pipeline**: Disabled in Terraform (future integration)
- **WordPress-OpenWebUI Connector**: Disabled (future integration)

## Essential Commands

### Cluster Access
```bash
# Get kubeconfig
ionosctl k8s kubeconfig get --cluster-id 354372a8-cdfc-4c4c-814c-37effe9bf8a2

# Verify cluster
kubectl --kubeconfig=./kubeconfig.yaml get pods -A
```

### Test Services
```bash
# WordPress (WORKING)
curl -H "Host: wordpress-tenant1.local" http://85.215.220.121/
curl -H "Host: wordpress-tenant1.local" http://85.215.220.121/wp-json/wp/v2/posts

# OpenWebUI (WORKING)  
curl -H "Host: openwebui.local" http://85.215.220.121/
curl -H "Host: openwebui.local" http://85.215.220.121/api/config

# Port-forward alternative
kubectl --kubeconfig=./kubeconfig.yaml port-forward -n admin-apps svc/open-webui 8080:80
```

### Authentik Management
```bash
# Check status (currently disabled)
kubectl --kubeconfig=./kubeconfig.yaml get deployment -n admin-apps | grep authentik

# Re-enable (requires PostgreSQL cluster first)
kubectl --kubeconfig=./kubeconfig.yaml scale deployment authentik-server -n admin-apps --replicas=1
kubectl --kubeconfig=./kubeconfig.yaml scale deployment authentik-worker -n admin-apps --replicas=1
```

## Key Implementation Insights

### Major Discovery
**System was MORE functional than expected** - Most "critical issues" documented were not actual failures:

1. **WordPress Database**: Never broken - MariaDB connectivity working perfectly
2. **OpenWebUI Access**: Ingress already configured and operational  
3. **Only Real Issue**: Authentik PostgreSQL dependency (resolved by disabling for PoC)
4. **Infrastructure**: IONOS services completely stable throughout

### What This Means
- **PoC Ready**: Both WordPress and OpenWebUI fully functional for demonstration
- **Integration Foundation**: Stable base for future WordPress-OpenWebUI connector work
- **Next Steps**: Deploy PostgreSQL cluster to re-enable Authentik SSO when needed

### Architecture Status
- **Infrastructure Layer**: ✅ STABLE (IONOS MKS, MariaDB, S3, Networking)
- **Platform Layer**: ✅ OPERATIONAL (Ingress, OpenWebUI + Ollama/Pipelines)  
- **Tenant Layer**: ✅ FUNCTIONAL (WordPress tenant1 with database connectivity)

## For Developers

**Quick Start**: Use the cluster access commands above, both services are externally accessible via LoadBalancer.

**Future Integration**: Re-enable Authentik SSO and OAuth2 pipeline when PostgreSQL cluster is deployed.

**Troubleshooting**: See `.claude/CLAUDE.md` for detailed troubleshooting patterns and architectural knowledge.

## Claude Code Development Guidelines

### Priority Integration Tasks
1. **PostgreSQL Deployment**: Add IONOS PostgreSQL cluster for Authentik
2. **Authentik SSO**: Scale from 0 to enable authentication
3. **OAuth2 Integration**: Enable WordPress ↔ OpenWebUI communication  
4. **Content Pipeline**: Activate WordPress MCP plugin integration
5. **GitHub Workflow**: Complete end-to-end deployment validation

### Quick Development Commands
```bash
# Environment setup
ionosctl k8s kubeconfig get --cluster-id 354372a8-cdfc-4c4c-814c-37effe9bf8a2
export KUBECONFIG=./kubeconfig.yaml

# Integration health check
kubectl get pods -A | grep -E "(authentik|wordpress|openwebui)"

# Test WordPress-OpenWebUI connectivity
curl -H "Host: wordpress-tenant1.local" http://85.215.220.121/wp-json/wp/v2/
curl -H "Host: openwebui.local" http://85.215.220.121/api/config

# Check PostgreSQL status (required for Authentik)
kubectl get postgresql -n admin-apps || echo "PostgreSQL deployment needed"

# GitHub Actions validation
gh workflow run deploy.yml --ref main
```

### Critical Implementation Files
- `terraform/infrastructure/` - PostgreSQL cluster deployment
- `terraform/platform/` - Authentik configuration updates
- `charts/authentik/` - SSO service deployment
- `docker/wordpress/` - MCP plugin activation
- `pipelines/` - OAuth2 service enablement
- `.github/workflows/` - CI/CD automation completion