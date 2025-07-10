# IONOS WordPress-OpenWebUI Project

## Project Overview

This project provides Infrastructure as Code (IaC) for deploying a WordPress and OpenWebUI integration with Authentik SSO on IONOS Cloud Managed Kubernetes.

**Cluster**: `<cluster-id>` | **LoadBalancer**: `<loadbalancer-ip>`

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
- **Infrastructure Details**: See `docs/INFRASTRUCTURE_STATUS.md`
- **Architecture Overview**: See `docs/ARCHITECTURE_STATUS.md`
- **Developer Commands**: See `docs/DEVELOPER_QUICKSTART.md`
- **Implementation Status**: See `docs/IMPLEMENTATION_STATUS.md`

## Essential Quick Commands

### Cluster Access
```bash
# Prefer existing cluster-admin@mks-cluster context if available
kubectl config current-context  # Check if cluster-admin@mks-cluster exists
kubectl get pods -A  # Use existing context if available

# Fallback: Pull new kubeconfig if needed
ionosctl k8s kubeconfig get --cluster-id <cluster-id>
kubectl --kubeconfig=./kubeconfig.yaml get pods -A
```

### Service Testing
```bash
# Test all services are responding
curl -H "Host: wordpress-tenant1.local" http://<loadbalancer-ip>/wp-json/wp/v2/
curl -H "Host: openwebui.local" http://<loadbalancer-ip>/api/config
curl -H "Host: authentik.local" http://<loadbalancer-ip>/ -I
```

### Configuration Updates
1. **Ollama Migration**: Ollama configuration replaced with IONOS OpenAI API
   - Configuration templates updated
   - See: `docs/OPENAI_API_CONFIGURATION.md`

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

### Known Issues
1. **Platform Resource Import**: Resource import procedures available for Terraform state management
2. **Authentik Helm Release Ownership**: Potential resource ownership conflicts
   - Existing helm release may have resource ownership conflicts
   - force_update and recreate_pods flags available to handle upgrades
   - May require manual cleanup of conflicting ServiceAccounts
3. **OAuth2 Frontend UI**: "Login with Authentik SSO" button integration
   - Backend authentication configured
   - Frontend integration implementation needed
4. **Tenant Configuration**: 
   - MariaDB CIDR range needs RFC1918 compliance
   - NetworkPolicy egress rule needs proper peer specification

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
- **WordPress**: `wordpress-tenant1.local` → `<loadbalancer-ip>`
- **OpenWebUI**: `openwebui.local` → `<loadbalancer-ip>`  
- **Authentik**: `authentik.local` → `<loadbalancer-ip>`
- **Admin Recovery**: `/recovery/use-token/cw3mx6Wp7CqGHizn4aOGJNkwgrBTuiRZf4YhQ9pOHe5iBcbOnxsi9ZwrZ8vG/`

## OAuth2 Credentials
- **WordPress**: `wordpress-client` / `wordpress-secret-2025`
- **OpenWebUI**: `openwebui-client` / `openwebui-secret-2025`

---

*This file serves as the primary context for Claude Code AI assistance. For detailed information, follow the documentation references above.*