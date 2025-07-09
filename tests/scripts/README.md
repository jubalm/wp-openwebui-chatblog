# Test Scripts Documentation

This directory contains validation and testing scripts for the WordPress-OpenWebUI integration platform.

## Overview

These scripts provide comprehensive testing capabilities for:
- Platform integration validation
- SSO/OAuth2 functionality testing
- Content automation pipeline verification
- Interactive platform demonstrations

## Available Test Scripts

### 1. test-integration.sh
**Purpose**: Comprehensive health check for all platform components

**Tests**:
- Cluster connectivity and node health
- Pod status across all namespaces
- LoadBalancer accessibility
- WordPress service and REST API
- OpenWebUI service and OAuth2 configuration
- Authentik SSO and OIDC discovery
- Pipeline service health
- Performance metrics

**Usage**:
```bash
# Run full integration test
export IONOS_TOKEN=your_token_here
./tests/scripts/test-integration.sh
```

**Output**: Detailed test results with pass/fail summary

### 2. test-sso-integration.sh
**Purpose**: Validates SSO and OAuth2 authentication flow

**Tests**:
- Authentik service availability
- OAuth2 discovery endpoints
- OpenWebUI OAuth2 configuration
- OAuth2 client secrets
- Authorization, token, and userinfo endpoints
- Network connectivity between services

**Usage**:
```bash
# Requires kubeconfig.yaml in project root
./tests/scripts/test-sso-integration.sh
```

**Prerequisites**:
- Valid kubeconfig at `./kubeconfig.yaml`
- kubectl installed

### 3. test-content-automation.sh
**Purpose**: Tests the WordPress content publishing automation pipeline

**Tests**:
- Pipeline service health endpoints
- WordPress REST API availability
- OpenWebUI pipelines integration
- Python module imports and functionality
- Content automation workflow components

**Usage**:
```bash
# Run content automation tests
./tests/scripts/test-content-automation.sh
```

**Features Tested**:
- Content extraction from conversations
- Title generation
- Excerpt and tag generation
- SEO optimization
- Multi-content type support

### 4. demo-tenant-system.sh
**Purpose**: Interactive demonstration of the multi-tenant platform

**Features**:
- Guided walkthrough of platform capabilities
- Live status checks
- Architecture visualization
- Tier comparison
- Content automation demonstration
- Access URL information

**Usage**:
```bash
# Run interactive demo
./tests/scripts/demo-tenant-system.sh
```

**Demo Sections**:
1. Current platform status
2. Tenant management operations
3. Tier comparison (free/pro/enterprise)
4. Content automation features
5. Architecture overview
6. Access information
7. Getting started guide

## Environment Requirements

### Required Variables
```bash
# For test-integration.sh
export IONOS_TOKEN=your_ionos_api_token

# Default values used by scripts
CLUSTER_ID="354372a8-cdfc-4c4c-814c-37effe9bf8a2"
LOADBALANCER_IP="85.215.220.121"
KUBECONFIG_PATH="./kubeconfig.yaml"
```

### Prerequisites
- `kubectl` - Kubernetes CLI
- `curl` - HTTP testing
- `jq` - JSON processing
- `python3` - For content automation tests
- `bc` - For performance calculations (optional)

## Test Scenarios

### Complete Platform Validation
```bash
# 1. Get cluster access
ionosctl k8s kubeconfig get --cluster-id 354372a8-cdfc-4c4c-814c-37effe9bf8a2

# 2. Run integration tests
export IONOS_TOKEN=your_token
./tests/scripts/test-integration.sh

# 3. Test SSO integration
./tests/scripts/test-sso-integration.sh

# 4. Test content automation
./tests/scripts/test-content-automation.sh
```

### Pre-deployment Validation
```bash
# Check if platform is ready for tenant provisioning
./tests/scripts/test-integration.sh | grep "Summary"
```

### Demo for Stakeholders
```bash
# Run interactive demonstration
./tests/scripts/demo-tenant-system.sh
```

## Understanding Test Results

### Success Indicators
- ✅ Green checkmarks indicate passing tests
- HTTP 200/302 responses where expected
- "healthy" status from health endpoints
- All pods in "Running" state

### Common Issues
- ❌ Red X marks indicate failures
- ⚠️ Yellow warnings for non-critical issues
- HTTP timeouts may indicate network issues
- Module import errors suggest missing dependencies

### Test Summary
Each script provides a summary at the end:
```
📊 Test Summary
==================================
Tests passed: 15
Tests failed: 2
Total tests: 17
```

## Extending Tests

### Adding New Tests
1. Follow the existing color coding convention
2. Use the utility functions (log_info, log_success, log_error)
3. Increment test counters appropriately
4. Provide clear test descriptions
5. Include expected vs actual output for failures

### Test Function Template
```bash
test_new_feature() {
    log_section "Testing New Feature"
    echo ""
    
    if [[ $(command_to_test) == "expected_result" ]]; then
        log_success "New feature test passed"
    else
        log_error "New feature test failed"
    fi
    
    echo ""
}
```

## CI/CD Integration

These test scripts can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions integration
- name: Run integration tests
  run: |
    export IONOS_TOKEN=${{ secrets.IONOS_TOKEN }}
    ./tests/scripts/test-integration.sh
```

## Related Documentation

- [Scripts Documentation](../../scripts/README.md)
- [Developer Quickstart](../../docs/DEVELOPER_QUICKSTART.md)
- [Implementation Status](../../docs/IMPLEMENTATION_STATUS.md)
- [GitHub Actions Workflows](../../.github/workflows/)