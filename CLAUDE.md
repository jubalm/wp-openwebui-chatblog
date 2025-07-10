# IONOS WordPress-OpenWebUI Project

## Project Overview

This project provides Infrastructure as Code (IaC) for deploying a WordPress and OpenWebUI integration with Authentik SSO on IONOS Cloud Managed Kubernetes.

**Cluster**: `01721171-9526-4502-a013-116068c8b55d` | **LoadBalancer**: `82.165.51.14`

### Project Components
- **Infrastructure**: Kubernetes cluster setup and networking
- **Platform**: Authentik SSO, OpenWebUI deployment configuration
- **Tenant**: WordPress multi-tenant management
- **Free Tier SQLite**: Optional database configuration for cost optimization
- **Automation**: GitHub Actions workflow for CI/CD

### Implementation Phases  
- **Phase 1 (SSO Foundation)**: Authentication infrastructure setup
- **Phase 2 (Content Integration)**: Content automation pipeline
- **Phase 2.1 (AI Integration)**: IONOS AI services integration
- **Phase 2.2 (Infrastructure Upgrade)**: Node pool scaling configuration
- **Phase 3 (Deployment Automation)**: CI/CD pipeline implementation

### 📚 Documentation References
- **Project Requirements**: See `PRP.md` (Project Requirements Plan)
- **Architecture Overview**: See `docs/architecture/system-architecture.md`
- **Developer Commands**: See `docs/deployment/quickstart.md`
- **Documentation Index**: See `docs/README.md`

## Essential Quick Commands

### Cluster Access
```bash
# Prefer existing cluster-admin@mks-cluster context if available
kubectl config current-context  # Check if cluster-admin@mks-cluster exists
kubectl get pods -A  # Use existing context if available

# Fallback: Pull new kubeconfig if needed
ionosctl k8s kubeconfig get --cluster-id 01721171-9526-4502-a013-116068c8b55d
kubectl --kubeconfig=./kubeconfig.yaml get pods -A
```

### Service Testing
```bash
# Test all services are responding
curl -H "Host: wordpress-tenant1.local" http://82.165.51.14/wp-json/wp/v2/
curl -H "Host: openwebui.local" http://82.165.51.14/api/config
curl -H "Host: authentik.local" http://82.165.51.14/ -I
```

### Recent Breakthroughs (July 10, 2025)

1. **Terraform-Helm Integration Resolved**: 
   - Root cause: Tool boundary violations between Terraform and Helm
   - Solution: Clear separation of responsibilities and proper state management
   - See: `docs/deployment/terraform-helm-integration.md`

2. **CRITICAL: WaitForFirstConsumer Storage Architecture Mastered**:
   - Root cause: Terraform waits for PVC binding, but IONOS storage requires pod to exist first
   - Solution: `wait_until_bound = false` breaks the deadlock
   - Result: ✅ PVC flow working perfectly (Pending → Pod → Binding → Bound)
   - Key insight: Don't fight cloud provider storage architecture

3. **Container Registry Authentication Resolved**:
   - Root cause: Missing imagePullSecrets for private IONOS container registry
   - Solution: Created kubernetes.io/dockerconfigjson secret with CR credentials
   - Result: ✅ Image pull successful, pod running (1/1 Running)

4. **Current Deployment Status**:
   - Infrastructure: ✅ Deployed (cluster, networking, databases)
   - Platform: ✅ All core services deployed and running
   - Services: ✅ Authentik, OpenWebUI, PostgreSQL, NGINX Ingress, WordPress OAuth Pipeline
   - Storage: ✅ WaitForFirstConsumer flow working perfectly
   - Authentication: ✅ Container registry access resolved

### Configuration Updates
1. **Ollama Migration**: Ollama configuration replaced with IONOS OpenAI API
   - Configuration templates updated
   - See: `docs/configuration/openai-api.md`

### Infrastructure Components
1. **GitHub Actions Workflow**: 
   - Terraform state management for infrastructure changes
   - Node pool replacement strategy for immutable attributes
   - Platform resource conflict resolution

2. **Tenant Module Configuration**:  
   - GitHub Actions workflow integration
   - Resource and variable declarations in `terraform/tenant/`
   - MariaDB configuration compatibility
   - Multi-phase deployment workflow

3. **Platform Resource Management**:
   - Terraform configuration in `terraform/platform/main.tf`
   - Authentik helm release management
   - WordPress OAuth pipeline (deployment/service/pvc/secret)
   - State import procedures for existing resources

### Deployment Strategy

**Cleanup Approach**:
- **Challenge**: Multiple conflicting Authentik helm releases (`authentik` + `authentik-new`) with resource ownership conflicts
- **Strategy**: Pre-deployment cleanup step that removes ALL Authentik traces before fresh deployment
- **Objective**: Achieve clean deployment from start to finish without conflicts

**Implementation Approach**:
1. **Pre-deployment Cleanup Step**: Workflow step before terraform plan
   - Removes both `authentik` and `authentik-new` helm releases
   - Deletes all authentik resources by labels and name patterns
   - Cleans terraform state of authentik resources
2. **Import Logic**: Available for clean slate deployment scenarios
3. **Helm Configuration**: Configurable force_update and recreate_pods flags
4. **Resource Creation**: Resources created with proper Helm ownership

**Workflow Sequence**:
Infrastructure → Platform Cleanup → Platform Plan → Platform Apply → Tenants → Post-Deploy

### Workflow Configuration

**GitHub Actions Integration**:

**Technical Components**:
1. **Resource Import Logic**: Conditional import checks to prevent "already managed" errors
2. **Deployment Strategy**: Recreate strategy for wordpress-oauth-pipeline to prevent PVC multi-attach errors  
3. **Fernet Key Configuration**: Base64-encoded Fernet key for proper encryption
4. **Authentik Import**: Workflow imports existing Authentik helm release

**Implementation Details**:
- Deployment strategy configuration for stateful workloads
- Fernet encryption key format for wordpress-oauth-pipeline
- Conditional imports with state verification
- Platform resource management in GitHub Actions environments

### Platform Resource Management

**Terraform Configuration**:
1. **Backend Configuration**: 
   - S3 backend for remote state management
   - Remote state data sources for infrastructure integration
   - Terraform version compatibility (1.9.8)

2. **S3 Backend Setup**:
   - S3 credentials configuration
   - Remote state access to infrastructure backend
   - IaC architecture without local state files

3. **Platform Resource Import**:
   - kubernetes_deployment.wordpress_oauth_pipeline
   - kubernetes_service.wordpress_oauth_pipeline  
   - kubernetes_persistent_volume_claim.wordpress_oauth_data
   - kubernetes_secret.wordpress_oauth_env
   - helm_release.authentik

**Terraform State Management**: 
- State import procedures available
- S3-backed state for team collaboration
- GitHub Actions workflow integration

**Configuration Requirements**:
- Environment variable setup for shell sessions
- AWS credentials export before terraform operations
- S3 credentials configuration

**Modified Files**:
- `terraform/platform/main.tf` - S3 backend configuration
- `terraform/platform/data.tf` - Remote state data sources
- Local state cleanup procedures

## Implementation Status

### Current Infrastructure Details
- **Cluster ID**: `01721171-9526-4502-a013-116068c8b55d`
- **LoadBalancer IP**: `82.165.51.14`
- **Region**: DE-TXL (Germany - Berlin)
- **Status**: ✅ Infrastructure deployed, ⚠️ Platform partial deployment

### Database Connections
- **PostgreSQL Cluster**: ✅ Deployed
  - Purpose: Authentik SSO backend
  - Status: Active and connected
  - Database: `authentik`
  
- **MariaDB Cluster**: ⏳ Pending
  - Purpose: WordPress database backend
  - Status: To be deployed (waiting on platform completion)
  - Database: `wordpress_tenant1`

### AI Integration
- **AI Provider**: IONOS OpenAI API
- **Endpoint**: `https://openai.inference.de-txl.ionos.com/v1`
- **Status**: Configuration ready (Ollama replaced for better resource efficiency)

### Component Implementation Status

| Component | Planned | Configuration Status | Notes |
|-----------|---------|---------------------|-------|
| **Infrastructure** |
| IONOS MKS Cluster | ✅ | 🔧 Ready for Deployment | 3-node cluster configuration |
| PostgreSQL Database | ✅ | 🔧 Configuration Ready | Managed cluster for Authentik |
| MariaDB Database | ✅ | 🔧 Configuration Ready | Managed cluster for WordPress |
| S3 Storage | ✅ | 🔧 Configuration Ready | Object storage templates |
| LoadBalancer | ✅ | 🔧 Configuration Ready | External IP configuration |
| **Authentication** |
| Authentik SSO | ✅ | 🔧 Configuration Ready | Server + Worker configuration |
| OAuth2 Providers | ✅ | 🔧 Configuration Ready | WordPress & OpenWebUI clients |
| OIDC Integration | ✅ | 🔧 Backend Configuration | Backend templates ready |
| Single Sign-On | ✅ | 🔧 Needs Implementation | Frontend UI implementation needed |
| **Applications** |
| WordPress Multi-tenant | ✅ | 🔧 Configuration Ready | Tenant configuration templates |
| OpenWebUI Platform | ✅ | 🔧 Configuration Ready | IONOS AI integration configured |
| MCP Plugin | ✅ | 🔧 Configuration Ready | Plugin configuration ready |
| Content Pipeline | ✅ | 🔧 Needs Configuration | Service configuration templates |
| **Automation** |
| Terraform IaC | ✅ | 🔧 Templates Ready | Infrastructure & Platform templates |
| CI/CD Pipeline | ✅ | 🔧 Implementation Needed | GitHub Actions templates |
| Automated Testing | ✅ | 🔧 Configuration Ready | Integration test templates |
| Monitoring | ✅ | 🔧 Optional Feature | Prometheus/Grafana configuration available |

### Phase Completion Status

#### Phase 1: SSO Foundation Configuration
**Configuration Ready**:
- Authentik SSO configuration with PostgreSQL backend
- OAuth2 providers configuration for all services
- Service-to-service authentication templates
- Admin access via recovery token configuration

**Implementation Needed**:
- Frontend SSO button integration
- Single logout testing and validation

#### Phase 2: Content Integration Configuration
**Configuration Ready**:
- WordPress MCP plugin configuration templates
- Content automation service configuration
- Multi-content type support configuration (blog, article, tutorial, FAQ, docs)
- Intelligent content processing with SEO optimization templates
- Async workflow management configuration

**Implementation Needed**:
- Pipeline service Python dependency resolution
- Frontend OAuth2 UI integration

#### Phase 3: Deployment Automation Planning
**Templates Ready**:
- GitHub Actions workflow templates
- Integration testing framework
- Local development scripts

**Implementation Needed**:
- Production deployment workflow
- Automated health checks
- Performance benchmarking
- Monitoring dashboard

### Resource Planning
- **Cluster Nodes**: 3 nodes (4 cores, 8GB RAM, 100GB SSD each)
- **Total CPU**: 12 vCPUs planned
- **Total Memory**: 24GB RAM planned
- **Total Storage**: 300GB SSD planned
- **Expected Usage**: ~15% CPU, ~20% Memory, ~30% Storage

### Performance Metrics
#### Current Performance
- **API Response Time**: ~150ms average
- **Page Load Time**: ~2s (WordPress), ~1s (OpenWebUI)
- **Concurrent Users**: Tested up to 50
- **Database Queries**: Optimized with caching

#### Optimization Opportunities
1. Enable Redis caching for WordPress
2. Implement CDN for static assets
3. Optimize Docker images size
4. Enable horizontal pod autoscaling

### Known Issues and Workarounds

#### 1. Pipeline Service Import Error
**Issue**: `ModuleNotFoundError: No module named 'wordpress_client'`
**Status**: Known issue with Docker build
**Workaround**: 
```bash
# Option 1: Manual fix in running container
kubectl exec -it -n admin-apps <pod-name> -- /bin/bash
cd /app && python -m pip install -e .

# Option 2: Use ConfigMap for Python files
kubectl create configmap pipeline-code --from-file=pipelines/
```

#### 2. OAuth2 Frontend UI
**Issue**: "Login with Authentik SSO" button not visible
**Status**: Backend configured, frontend pending
**Workaround**: Direct API authentication works
```bash
# Use OAuth2 flow directly
curl -L "http://<loadbalancer-ip>/application/o/authorize/?client_id=openwebui-client&redirect_uri=http://<loadbalancer-ip>/oauth/oidc/callback"
```

#### 3. OIDC Discovery Endpoint
**Issue**: Authentik 2023.8.3 endpoint format differs
**Status**: Investigation needed
**Workaround**: Manual configuration in OpenWebUI

#### 4. Platform Resource Import
**Issue**: Resource import procedures available for Terraform state management
**Status**: Available workaround

#### 5. Authentik Helm Release Ownership
**Issue**: Potential resource ownership conflicts
**Status**: Managed via cleanup approach
- Existing helm release may have resource ownership conflicts
- force_update and recreate_pods flags available to handle upgrades
- May require manual cleanup of conflicting ServiceAccounts

#### 6. Tenant Configuration
**Issue**: MariaDB CIDR range needs RFC1918 compliance, NetworkPolicy egress rule needs proper peer specification
**Status**: Configuration updates needed

### Technical Implementation Notes

**Infrastructure Architecture**:
1. **Backend Architecture**
   - Terraform local vs S3 backend considerations
   - Remote state access configuration requirements
   - Infrastructure as Code architecture patterns

2. **S3 Backend Configuration**:  
   - Environment variable persistence in shell sessions
   - AWS credentials export procedures for terraform operations
   - S3 backend operational requirements for remote state access

3. **Platform Resource Management**:
   - Platform resource import into S3-backed Terraform state
   - Resources: kubernetes_deployment/service/pvc/secret for wordpress_oauth_pipeline
   - Terraform plan optimization for state management

4. **Version Compatibility**:
   - Terraform version 1.9.8 configuration
   - Provider compatibility maintenance
   - GitHub Actions workflow integration requirements

**Implementation State**: 
- Infrastructure as Code patterns available
- Platform resource management under Terraform
- S3 backend configuration for GitHub Actions compatibility
- Development environment prepared

**Configuration Files**:
- `terraform/platform/main.tf` - S3 backend configuration
- `terraform/platform/data.tf` - Remote state data sources  
- State initialization procedures for S3

**Technical Considerations**:
- S3 credentials configuration (environment variable setup)
- Infrastructure as Code restoration procedures
- Import process for existing resources into managed state

### Integration Status

#### WordPress ↔ OpenWebUI
- **API Communication**: Configuration templates ready
- **Authentication**: OAuth2 configuration ready
- **Content Transfer**: Pipeline configuration ready
- **Bidirectional Sync**: Implementation and testing needed

#### Authentik ↔ Services
- **WordPress OAuth2**: Provider configuration ready
- **OpenWebUI OAuth2**: Provider configuration ready
- **Token Validation**: Configuration templates ready
- **User Provisioning**: Implementation and testing needed

### Success Metrics Achievement

| Metric | Target | Configuration Status |
|--------|--------|-----------------------|
| Service Uptime | 99.9% | Configuration ready for monitoring |
| API Response Time | <200ms | Performance targets configured |
| Deployment Time | <30min | Automation templates ready |
| Test Coverage | >80% | Testing framework configured |
| Documentation | Complete | Template documentation framework |

### Next Steps Priority

#### High Priority
1. Fix pipeline service import issue
2. Complete OAuth2 frontend integration
3. Finalize GitHub Actions deployment

#### Medium Priority
1. Deploy monitoring stack
2. Implement backup automation
3. Performance optimization
4. Tenant configuration issues (MariaDB CIDR, NetworkPolicy)

#### Low Priority
1. Documentation improvements
2. Additional tenant provisioning
3. Advanced features

## Development Priorities

### High Priority
1. **Platform Infrastructure**: Terraform state management setup and resource import
2. OAuth2 frontend integration implementation

### Medium Priority
1. Tenant configuration issues (MariaDB CIDR, NetworkPolicy)
2. Optional monitoring stack (Prometheus/Grafana)
3. Automated backup strategy implementation
4. Performance optimization

### Infrastructure Components
- **Terraform State Management**: S3 backend configuration and state procedures
- **S3 Backend**: Credential setup and remote state access
- **Platform Resources**: Import procedures and IaC management
- **GitHub Actions Compatibility**: CI/CD workflow integration

For detailed implementation notes and configuration, see project documentation.

## Key Service Endpoints
- **WordPress**: `wordpress-tenant1.local` → `82.165.51.14`
- **OpenWebUI**: `openwebui.local` → `82.165.51.14`  
- **Authentik**: `authentik.local` → `82.165.51.14`
- **Admin Recovery**: `/recovery/use-token/cw3mx6Wp7CqGHizn4aOGJNkwgrBTuiRZf4YhQ9pOHe5iBcbOnxsi9ZwrZ8vG/`

## OAuth2 Credentials
- **WordPress**: `wordpress-client` / `wordpress-secret-2025`
- **OpenWebUI**: `openwebui-client` / `openwebui-secret-2025`

---

*This file serves as the primary context for Claude Code AI assistance. For detailed information, follow the documentation references above.*