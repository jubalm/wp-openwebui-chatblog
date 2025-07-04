# IONOS WordPress-OpenWebUI Project - Current Deployment State

## Live Assessment Status (July 4, 2025)

**Project Memory**: See `CLAUDE.md` for stable architecture, commands, and troubleshooting patterns.
**This File**: Contains current deployment reality and active issues.

## Current Deployment Reality

### Cluster Information
- **Cluster ID**: `354372a8-cdfc-4c4c-814c-37effe9bf8a2`
- **External LoadBalancer IP**: `85.215.220.121`
- **Working Access Method**: `ionosctl k8s kubeconfig get --cluster-id 354372a8-cdfc-4c4c-814c-37effe9bf8a2`

### Infrastructure Layer Status: ✅ STABLE
- IONOS Managed Kubernetes (MKS) cluster running
- IONOS Managed MariaDB clusters (per WordPress tenant)
- IONOS S3-compatible backend storage
- Networking (VPC, LAN, datacenter)

### Platform Layer Status: ⚠️ MIXED
- ✅ **NGINX Ingress Controller** - Running with external IP available
- ✅ **OpenWebUI** - Running with full pipeline support
- ✅ **OpenWebUI Ollama** - Running  
- ✅ **OpenWebUI Pipelines** - Running
- ✅ **Kubernetes namespaces** (`admin-apps`, `ingress-nginx`, `tenant1`)

### Tenant Layer Status: ❌ BROKEN
- ⚠️ **WordPress tenant1** - Running but **❌ DATABASE ERROR**
- ❌ **MariaDB connections** - Connection failing to `ma-angemd97n8m01l5k.mariadb.de-txl.ionos.com`
- ✅ **Container registry secrets** - Working
- ✅ **Ingress configuration** - `wordpress-tenant1.local` → `85.215.220.121`

## Critical Issues Identified

### HIGH PRIORITY - Database Connectivity ❌
- **WordPress Database Error**: Connection to MariaDB host `ma-angemd97n8m01l5k.mariadb.de-txl.ionos.com` failing
- **Impact**: All WordPress functionality broken
- **Status**: Blocks all WordPress testing and functionality

### HIGH PRIORITY - Authentication Issues ⚠️
- **Authentik Server** - RUNNING BUT UNSTABLE (321 restarts on server pod)
- **Authentik Redis** - Running fine
- **Authentik Worker** - Running fine  
- **Dual Authentik deployments** - Both `admin-apps` and `default` namespaces

### MEDIUM PRIORITY - Integration Gaps ❌
- **WordPress OAuth2 Pipeline** - Disabled in Terraform (`terraform/platform/main.tf` lines 175-333)
- **WordPress-OpenWebUI connector service** - Disabled
- **OAuth2 ingress routing** - Disabled
- **OpenWebUI external access** - No ingress configured (needs port-forward)
- **PostgreSQL cluster** - Disabled (Authentik using Redis instead)

## Testing Results Summary

### WordPress External Access Testing
- ✅ **Traffic reaches WordPress** via LoadBalancer (85.215.220.121)
- ❌ **Database connection error** to MariaDB host
- ❌ **All WordPress functionality broken** due to database connectivity
- ❌ **WordPress API endpoints fail** - All return database errors

### OpenWebUI Testing
- ⚠️ **Pending** - Requires kubeconfig file access for port-forward testing

## Assessment Phase Progress

### Phase 1: Infrastructure Validation ✅ COMPLETED
- Cluster access restored via ionosctl
- Service status verified
- Network connectivity confirmed

### Phase 2: Minimal Functionality Testing ⚠️ IN PROGRESS
- WordPress external access confirmed but database broken
- OpenWebUI testing pending
- Basic integration testing blocked by database issues

### Phase 3: Critical Issue Resolution 🔄 NEXT PRIORITY
- Fix WordPress MariaDB connection (URGENT)
- Investigate Authentik restart loop
- Create OpenWebUI ingress for external access

## Current Commands for This Deployment

### Cluster Access
```bash
# Get current kubeconfig
ionosctl k8s kubeconfig get --cluster-id 354372a8-cdfc-4c4c-814c-37effe9bf8a2

# Basic cluster verification
kubectl --kubeconfig=./kubeconfig.yaml get nodes
kubectl --kubeconfig=./kubeconfig.yaml get pods -A
```

### WordPress Testing
```bash
# Test external access
curl -H "Host: wordpress-tenant1.local" http://85.215.220.121/

# Test WordPress API
curl -H "Host: wordpress-tenant1.local" http://85.215.220.121/wp-json/wp/v2/

# Database connectivity test from WordPress pod
kubectl --kubeconfig=./kubeconfig.yaml exec -n tenant1 [WORDPRESS_POD] -- mysql -h ma-angemd97n8m01l5k.mariadb.de-txl.ionos.com -u wpuser -p -e "SHOW DATABASES;"
```

### OpenWebUI Testing
```bash
# Port-forward for testing
kubectl --kubeconfig=./kubeconfig.yaml port-forward -n admin-apps svc/open-webui 8080:80

# Check OpenWebUI pod status
kubectl --kubeconfig=./kubeconfig.yaml get pods -n admin-apps -l app=open-webui
```

### Authentik Troubleshooting
```bash
# Check Authentik server logs
kubectl --kubeconfig=./kubeconfig.yaml logs -n admin-apps authentik-server-586cff45f5-dl5gn --tail=100

# Check duplicate Authentik deployment
kubectl --kubeconfig=./kubeconfig.yaml logs -n default authentik-new-server-7575d64578-mfstl --tail=100
```

## Current Deployment vs Intended Design

### What's Actually Working ✅
- Infrastructure layer completely functional
- NGINX Ingress Controller with external LoadBalancer
- OpenWebUI running (but no external access)
- WordPress containers running (but broken database)
- Container registry and image pulls working

### What's Currently Broken ❌
- WordPress database connectivity (complete functional failure)
- Authentik stability (321 restarts)
- All integration features (OAuth2 pipeline disabled)
- OpenWebUI external access (no ingress)
- SSO functionality (Authentik unstable)

### What's Disabled by Design ❌
- PostgreSQL cluster for Authentik
- WordPress OAuth2 pipeline service
- WordPress-OpenWebUI connector integration
- OAuth2 ingress routing

## Next Session Priorities

1. **URGENT**: Fix WordPress MariaDB connection issue
2. **HIGH**: Test OpenWebUI functionality via port-forward
3. **HIGH**: Investigate Authentik restart loop (321 restarts)
4. **MEDIUM**: Create OpenWebUI ingress for external access
5. **MEDIUM**: Clean up duplicate Authentik deployments

## Success Criteria

### Phase 2 Success (Current Target)
- [ ] WordPress admin interface accessible AND functional
- [ ] OpenWebUI chat interface functional
- [ ] Basic WordPress operations work (create/edit posts)

### Phase 3 Success (Next Target)
- [ ] WordPress MariaDB connection resolved
- [ ] Authentik restart loop resolved
- [ ] OpenWebUI externally accessible
- [ ] All services showing healthy status

## Risk Assessment

### High Risk
- ❌ **WordPress Database Connectivity** - Complete functionality blocked
- ⚠️ **Authentik Restart Loop** - 300+ restarts indicate critical config issue
- ⚠️ **No OpenWebUI External Access** - No ingress configured

### Medium Risk
- ⚠️ **Duplicate Authentik Deployments** - Resource waste and potential conflicts
- ⚠️ **Integration gaps** - OAuth2 pipeline disabled, no WordPress-OpenWebUI connection

### Low Risk
- ✅ **Resource capacity** - Infrastructure layer stable
- ✅ **Container registry** - Image pulls working
- ✅ **Network connectivity** - Ingress controller and LoadBalancer functional

## Current State Assessment Summary

### Key Findings from Live Testing
1. **ionosctl provides reliable cluster access** - More stable than manual kubeconfig
2. **System more functional than expected** - Core services operational despite disabled components
3. **Database connectivity is the primary blocker** - Not authentication/SSO issues
4. **Integration features were intentionally disabled** - Not deployment failures
5. **Ingress configuration works perfectly** - LoadBalancer and routing functional

### Reality vs Documentation
- **CLAUDE.md** described intended final state
- **Current reality** shows many components disabled/broken
- **Priority should be** stabilizing existing services before re-enabling disabled ones

### What This Means
- **WordPress is accessible** but completely non-functional due to database
- **OpenWebUI is functional** but has no external access
- **Authentik exists** but is unstable and not providing SSO
- **Integration pipeline** exists in code but is disabled in deployment