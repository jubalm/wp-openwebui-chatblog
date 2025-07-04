# WordPress-OpenWebUI PoC Deployment Fix - Project Requirements Planning (PRP)

**Document**: WordPress_OpenWebUI_PoC_Deployment_Fix_PRP_2025-07-04.md  
**Project**: IONOS WordPress-OpenWebUI Integration Platform  
**Focus**: Deployment Issue Resolution for Proof of Concept  
**Date**: July 4, 2025  
**Status**: Active Development  

---

## 🎯 Project Overview

### Project Name
**WordPress-OpenWebUI PoC Deployment Fix**

### Project Description
Fix critical deployment issues in the IONOS WordPress-OpenWebUI integration platform to achieve a working Proof of Concept. Focus on resolving database connectivity, authentication stability, and basic service functionality.

### Project Type
**Infrastructure Repair & Stabilization** - Fixing existing cloud-native deployment issues

### Project Context
- **Current State**: Partially deployed with critical failures
- **Infrastructure**: IONOS Managed Kubernetes, MariaDB, S3 storage
- **Architecture**: Multi-tenant WordPress + OpenWebUI with Authentik SSO
- **Priority**: PoC validation over feature completeness

---

## 🔧 Technical Context

### Technology Stack
- **Cloud Provider**: IONOS Cloud (Kubernetes MKS, MariaDB, S3)
- **Orchestration**: Terraform, Helm Charts, Kubernetes
- **Applications**: WordPress, OpenWebUI, Authentik
- **Languages**: PHP, Python, Shell scripting
- **Networking**: NGINX Ingress Controller, LoadBalancer (85.215.220.121)

### Current Deployment Status
- **Infrastructure Layer**: ✅ STABLE
- **Platform Layer**: ⚠️ MIXED (services running but issues present)
- **Application Layer**: ❌ BROKEN (WordPress database failure)

### Affected Systems
- **WordPress tenant1**: Database connectivity completely broken
- **Authentik**: Unstable with 321 restarts
- **OpenWebUI**: Functional but no external access
- **MariaDB**: Connection failing to `ma-angemd97n8m01l5k.mariadb.de-txl.ionos.com`

---

## 🎯 Business Requirements

### Problem Statement
The WordPress-OpenWebUI integration PoC is currently non-functional due to:
1. WordPress cannot connect to MariaDB (complete functionality failure)
2. Authentik authentication service is unstable (321 restarts)
3. OpenWebUI lacks external access for testing
4. System cannot demonstrate basic PoC functionality

### Success Criteria
**Phase 1 - Critical Fix (WordPress Database)**
- [ ] WordPress admin interface accessible and functional
- [ ] WordPress can create/edit posts successfully
- [ ] Database connectivity stable and reliable
- [ ] WordPress API endpoints responding correctly

**Phase 2 - Authentication Stability (Authentik)**
- [ ] Authentik server running without restart loops
- [ ] Authentication service stable for basic testing
- [ ] Duplicate deployments cleaned up
- [ ] Service logs showing healthy operation

**Phase 3 - External Access (OpenWebUI)**
- [ ] OpenWebUI accessible externally (ingress or port-forward)
- [ ] Chat interface functional
- [ ] Basic AI pipeline operations working
- [ ] Integration points identified for future development

### Primary Stakeholders
- **Technical Lead**: Needs working PoC for validation
- **Development Team**: Requires stable foundation for integration work
- **Business Stakeholders**: Expecting PoC demonstration

---

## 🔍 Functional Requirements

### Core Functionality - WordPress Database Fix
**Priority**: 🔴 CRITICAL
- **Function**: Establish working MariaDB connection
- **Input**: Database credentials, connection strings, network configuration
- **Output**: Functional WordPress installation with database access
- **Acceptance**: WordPress admin dashboard loads and functions normally

### Core Functionality - Authentik Stability
**Priority**: 🟡 HIGH
- **Function**: Resolve authentication service restart loop
- **Input**: Authentik configuration, resource limits, network settings
- **Output**: Stable Authentik service with consistent uptime
- **Acceptance**: Service running >1 hour without restarts

### Core Functionality - OpenWebUI Access
**Priority**: 🟢 MEDIUM
- **Function**: Enable external access to OpenWebUI
- **Input**: Ingress configuration or port-forward setup
- **Output**: Accessible OpenWebUI interface
- **Acceptance**: Chat interface loads and responds to basic queries

### User Workflows
1. **WordPress Testing**: Admin login → Create post → Verify database operations
2. **Authentik Testing**: Service status → Log review → Stability verification
3. **OpenWebUI Testing**: External access → Chat interface → Basic AI interaction

---

## ⚙️ Technical Requirements

### Performance Requirements
- **WordPress**: Response time <5 seconds for admin operations
- **Authentik**: Service restart interval >1 hour (stability baseline)
- **OpenWebUI**: Chat response time <10 seconds for basic queries

### Security Requirements
- **Database**: Secure connection to MariaDB with proper credentials
- **Network**: Maintain existing ingress security configurations
- **Authentication**: Functional SSO pipeline (even if simplified for PoC)

### Scalability Considerations
- **Single Tenant**: Focus on tenant1 WordPress instance only
- **Resource Limits**: Work within existing cluster capacity
- **Future Expansion**: Maintain architecture for later multi-tenant scaling

### Compatibility Requirements
- **IONOS Cloud**: Compatible with existing MKS cluster
- **Kubernetes**: Work with current namespace structure
- **Terraform**: Maintain existing infrastructure-as-code approach

---

## 📋 Dependencies

### External Dependencies
- **IONOS MariaDB**: `ma-angemd97n8m01l5k.mariadb.de-txl.ionos.com` accessibility
- **IONOS Cluster**: Kubernetes cluster `354372a8-cdfc-4c4c-814c-37effe9bf8a2`
- **LoadBalancer**: External IP `85.215.220.121` availability
- **DNS**: `wordpress-tenant1.local` resolution

### Internal Dependencies
- **Terraform State**: Existing infrastructure configuration
- **Helm Charts**: Current chart configurations for all services
- **Kubernetes Secrets**: Database credentials and API keys
- **Container Images**: WordPress, OpenWebUI, Authentik images

### Critical Path Dependencies
1. **Database Connectivity** → WordPress functionality
2. **WordPress Stability** → Integration testing capability
3. **Authentik Stability** → Future SSO integration
4. **OpenWebUI Access** → Complete PoC demonstration

---

## 🛠️ Implementation Guidance

### Development Approach
**Sequential Fix Strategy** - Address issues in priority order:
1. **WordPress Database** (blocks all functionality)
2. **Authentik Stability** (enables authentication testing)
3. **OpenWebUI Access** (completes PoC demonstration)

### Coding Standards
- **Infrastructure**: Follow existing Terraform patterns
- **Kubernetes**: Maintain current namespace and labeling conventions
- **Configuration**: Use existing Helm values structure
- **Documentation**: Update CLAUDE.md with fix details

### Testing Strategy
**Manual Testing Approach**:
- **WordPress**: Admin login, post creation, API endpoint testing
- **Authentik**: Service status monitoring, log analysis
- **OpenWebUI**: Interface access, basic chat functionality
- **Integration**: End-to-end user workflow testing

### Deployment Process
1. **Backup Current State**: Terraform state, database, configurations
2. **Incremental Fixes**: One issue at a time with verification
3. **Rollback Plan**: Ability to revert to previous state
4. **Documentation**: Record all changes in CLAUDE.md

---

## ⚠️ Risk Assessment

### High Risk Areas
**WordPress Database Connectivity**
- **Risk**: Complete WordPress functionality failure
- **Impact**: Blocks all PoC demonstration
- **Mitigation**: Database connection testing, credential verification
- **Contingency**: Temporary database setup if needed

**Authentik Configuration**
- **Risk**: Restart loop indicates fundamental configuration issue
- **Impact**: Authentication instability affects user experience
- **Mitigation**: Configuration review, resource analysis
- **Contingency**: Disable Authentik temporarily for PoC

### Medium Risk Areas
**Network Configuration**
- **Risk**: Ingress or LoadBalancer misconfiguration
- **Impact**: External access issues
- **Mitigation**: Network troubleshooting, DNS verification

**Resource Constraints**
- **Risk**: Cluster resource limits
- **Impact**: Service instability
- **Mitigation**: Resource usage monitoring

### Low Risk Areas
**OpenWebUI Functionality**
- **Risk**: AI pipeline issues
- **Impact**: Limited PoC demonstration
- **Mitigation**: Basic testing, minimal configuration

---

## 📊 Project Phases

### Phase 1: WordPress Database Fix (CRITICAL)
**Duration**: 1-2 days
**Deliverables**:
- [ ] MariaDB connection restored
- [ ] WordPress admin interface functional
- [ ] Database operations working
- [ ] WordPress API endpoints responding

**Success Metrics**:
- WordPress admin dashboard loads
- Posts can be created/edited
- Database queries execute successfully
- No database connection errors in logs

### Phase 2: Authentik Stability (HIGH)
**Duration**: 1-2 days
**Deliverables**:
- [ ] Authentik restart loop resolved
- [ ] Service running stably
- [ ] Configuration optimized
- [ ] Duplicate deployments cleaned up

**Success Metrics**:
- Service uptime >1 hour without restarts
- Healthy status in service logs
- Resource usage within normal limits
- Authentication endpoints responding

### Phase 3: OpenWebUI External Access (MEDIUM)
**Duration**: 1 day
**Deliverables**:
- [ ] External access configured
- [ ] Chat interface accessible
- [ ] Basic AI functionality working
- [ ] Integration points documented

**Success Metrics**:
- OpenWebUI interface loads externally
- Chat responses working
- AI pipeline functional
- Ready for integration testing

---

## 🎯 Immediate Next Steps

### 1. WordPress Database Investigation
```bash
# Test database connectivity from WordPress pod
kubectl --kubeconfig=./kubeconfig.yaml exec -n tenant1 [WORDPRESS_POD] -- mysql -h ma-angemd97n8m01l5k.mariadb.de-txl.ionos.com -u wpuser -p -e "SHOW DATABASES;"

# Check WordPress database configuration
kubectl --kubeconfig=./kubeconfig.yaml describe secret -n tenant1 wordpress-db-secret
```

### 2. Authentik Analysis
```bash
# Analyze Authentik logs for restart cause
kubectl --kubeconfig=./kubeconfig.yaml logs -n admin-apps authentik-server-586cff45f5-dl5gn --tail=100

# Check resource usage
kubectl --kubeconfig=./kubeconfig.yaml top pods -n admin-apps
```

### 3. OpenWebUI Access Setup
```bash
# Test current functionality
kubectl --kubeconfig=./kubeconfig.yaml port-forward -n admin-apps svc/open-webui 8080:80

# Plan ingress configuration
kubectl --kubeconfig=./kubeconfig.yaml get ingress -A
```

---

## 📈 Success Validation

### Validation Checklist
- [ ] WordPress admin interface accessible at `http://85.215.220.121` (Host: wordpress-tenant1.local)
- [ ] WordPress can create and save posts
- [ ] WordPress API endpoints return valid responses
- [ ] Authentik service shows stable status for >1 hour
- [ ] OpenWebUI interface accessible (port-forward or ingress)
- [ ] OpenWebUI chat functionality working
- [ ] All services showing healthy status in cluster
- [ ] No critical errors in service logs

### PoC Demonstration Ready
- [ ] WordPress content management functional
- [ ] Basic authentication working (even if simplified)
- [ ] OpenWebUI AI chat interface operational
- [ ] System stable enough for integration planning
- [ ] Documentation updated with working configuration

---

## 📚 References

### Project Documentation
- **CLAUDE.md**: Current deployment status and troubleshooting
- **terraform/platform/main.tf**: Infrastructure configuration
- **charts/**: Helm chart configurations
- **docs/TROUBLESHOOTING.md**: Known issues and solutions

### Technical Resources
- **IONOS Cloud Documentation**: Kubernetes, MariaDB, networking
- **WordPress Configuration**: Database setup, container configuration
- **Authentik Documentation**: SSO setup, troubleshooting
- **OpenWebUI Documentation**: Deployment, configuration

### Monitoring & Logs
- **Kubernetes**: `kubectl logs`, `kubectl describe`, `kubectl get`
- **Cluster Access**: `ionosctl k8s kubeconfig get --cluster-id 354372a8-cdfc-4c4c-814c-37effe9bf8a2`
- **Service Status**: LoadBalancer IP `85.215.220.121`

---

*This PRP document serves as the comprehensive guide for fixing the WordPress-OpenWebUI PoC deployment issues. Update this document as fixes are implemented and new issues are discovered.*