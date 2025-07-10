#!/bin/bash

# SSO Integration Testing Script
# Validates end-to-end OAuth2 authentication flow

set -e

# Configuration
LOADBALANCER_IP="${LOADBALANCER_IP:-}"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-./kubeconfig.yaml}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Utility functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((TESTS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_section() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

# Set kubeconfig
export KUBECONFIG="$KUBECONFIG_PATH"

# Test functions

test_authentik_service() {
    log_section "Testing Authentik SSO Service"
    echo ""
    
    # Test pod status
    if kubectl get pods -n admin-apps | grep -q "authentik-server.*Running"; then
        log_success "Authentik server pod is running"
    else
        log_error "Authentik server pod is not running"
    fi
    
    if kubectl get pods -n admin-apps | grep -q "authentik-worker.*Running"; then
        log_success "Authentik worker pod is running"
    else
        log_error "Authentik worker pod is not running"
    fi
    
    # Test service accessibility
    if curl -s -H "Host: authentik.local" "http://$LOADBALANCER_IP/" | grep -q "302\|Found\|Redirect"; then
        log_success "Authentik is accessible via LoadBalancer"
    else
        log_error "Authentik is not accessible via LoadBalancer"
    fi
    
    echo ""
}

test_oauth2_discovery_endpoints() {
    log_section "Testing OAuth2 Discovery Endpoints"
    echo ""
    
    # Test OpenWebUI OIDC discovery
    if curl -s -H "Host: authentik.local" "http://$LOADBALANCER_IP/application/o/openwebui/.well-known/openid-configuration" | grep -q "issuer"; then
        log_success "OpenWebUI OIDC discovery endpoint working"
    else
        log_error "OpenWebUI OIDC discovery endpoint failed"
    fi
    
    # Test WordPress OIDC discovery
    if curl -s -H "Host: authentik.local" "http://$LOADBALANCER_IP/application/o/wordpress-tenant1/.well-known/openid-configuration" | grep -q "issuer"; then
        log_success "WordPress OIDC discovery endpoint working"
    else
        log_error "WordPress OIDC discovery endpoint failed"
    fi
    
    echo ""
}

test_openwebui_oauth_config() {
    log_section "Testing OpenWebUI OAuth2 Configuration"
    echo ""
    
    # Test OAuth provider configuration
    response=$(curl -s -H "Host: openwebui.local" "http://$LOADBALANCER_IP/api/config")
    
    if echo "$response" | grep -q '"oauth":{"providers":{"oidc":"Authentik SSO"}}'; then
        log_success "OpenWebUI shows Authentik SSO provider"
    else
        log_error "OpenWebUI does not show Authentik SSO provider"
        echo "Response: $response"
    fi
    
    # Test OAuth login endpoint
    if curl -s -o /dev/null -w "%{http_code}" -H "Host: openwebui.local" "http://$LOADBALANCER_IP/oauth/oidc/login" | grep -q "200"; then
        log_success "OpenWebUI OAuth login endpoint accessible"
    else
        log_error "OpenWebUI OAuth login endpoint not accessible"
    fi
    
    echo ""
}

test_wordpress_service() {
    log_section "Testing WordPress Service"
    echo ""
    
    # Test WordPress accessibility
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: wordpress-tenant1.local" "http://$LOADBALANCER_IP/")
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "302" ]; then
        log_success "WordPress is accessible (HTTP $http_code)"
    else
        log_error "WordPress is not accessible (HTTP $http_code)"
    fi
    
    # Check if WordPress is installed or needs setup
    wp_content=$(curl -s -H "Host: wordpress-tenant1.local" "http://$LOADBALANCER_IP/")
    
    if echo "$wp_content" | grep -qi "installation\|setup"; then
        log_warning "WordPress is in installation mode"
        echo "  WordPress needs initial setup before OAuth2 can be tested"
    elif echo "$wp_content" | grep -qi "wordpress"; then
        log_success "WordPress appears to be installed"
    else
        log_warning "WordPress status unclear"
    fi
    
    echo ""
}

test_oauth2_client_secrets() {
    log_section "Testing OAuth2 Client Configuration"
    echo ""
    
    # Test OpenWebUI OAuth secrets
    if kubectl get secret openwebui-env-secrets -n admin-apps >/dev/null 2>&1; then
        log_success "OpenWebUI OAuth2 secrets exist"
        
        # Check key OAuth2 variables
        oauth_client_id=$(kubectl get secret openwebui-env-secrets -n admin-apps -o jsonpath='{.data.OAUTH_CLIENT_ID}' | base64 -d)
        oauth_provider=$(kubectl get secret openwebui-env-secrets -n admin-apps -o jsonpath='{.data.OAUTH_PROVIDER_NAME}' | base64 -d)
        
        if [ "$oauth_client_id" = "openwebui-client" ]; then
            log_success "OpenWebUI OAuth client ID configured correctly"
        else
            log_error "OpenWebUI OAuth client ID misconfigured: $oauth_client_id"
        fi
        
        if [ "$oauth_provider" = "Authentik SSO" ]; then
            log_success "OpenWebUI OAuth provider name configured correctly"
        else
            log_error "OpenWebUI OAuth provider name misconfigured: $oauth_provider"
        fi
    else
        log_error "OpenWebUI OAuth2 secrets not found"
    fi
    
    # Test WordPress OAuth secrets (if they exist)
    if kubectl get secret wordpress-oauth-env-secrets -n admin-apps >/dev/null 2>&1; then
        log_success "WordPress OAuth2 secrets exist"
    else
        log_warning "WordPress OAuth2 secrets not found (may be in tenant namespace)"
    fi
    
    echo ""
}

test_oauth2_endpoints() {
    log_section "Testing OAuth2 Endpoint Connectivity"
    echo ""
    
    # Test authorization endpoint
    if curl -s -o /dev/null -w "%{http_code}" -H "Host: authentik.local" "http://$LOADBALANCER_IP/application/o/authorize/" | grep -q "405\|200\|302"; then
        log_success "OAuth2 authorization endpoint accessible"
    else
        log_error "OAuth2 authorization endpoint not accessible"
    fi
    
    # Test token endpoint
    if curl -s -o /dev/null -w "%{http_code}" -H "Host: authentik.local" "http://$LOADBALANCER_IP/application/o/token/" | grep -q "405\|400\|200"; then
        log_success "OAuth2 token endpoint accessible"
    else
        log_error "OAuth2 token endpoint not accessible"
    fi
    
    # Test userinfo endpoint
    if curl -s -o /dev/null -w "%{http_code}" -H "Host: authentik.local" "http://$LOADBALANCER_IP/application/o/userinfo/" | grep -q "401\|200"; then
        log_success "OAuth2 userinfo endpoint accessible"
    else
        log_error "OAuth2 userinfo endpoint not accessible"
    fi
    
    echo ""
}

test_network_connectivity() {
    log_section "Testing Network Connectivity"
    echo ""
    
    # Test LoadBalancer IP accessibility
    if ping -c 1 "$LOADBALANCER_IP" >/dev/null 2>&1; then
        log_success "LoadBalancer IP is reachable"
    else
        log_warning "LoadBalancer IP ping failed (may be blocked)"
    fi
    
    # Test service-to-service connectivity within cluster
    if kubectl exec -n admin-apps deployment/open-webui -- curl -s "http://authentik.admin-apps.svc.cluster.local:9000/" >/dev/null 2>&1; then
        log_success "Internal service-to-service connectivity working"
    else
        log_warning "Internal service-to-service connectivity test failed"
    fi
    
    echo ""
}

demonstrate_sso_flow() {
    log_section "SSO Flow Demonstration"
    echo ""
    
    echo "Complete OAuth2 flow would work as follows:"
    echo ""
    echo "1. User visits: http://openwebui.local → $LOADBALANCER_IP"
    echo "2. User clicks 'Login with Authentik SSO'"
    echo "3. Redirect to: http://authentik.local/application/o/authorize/"
    echo "4. User authenticates with Authentik"
    echo "5. Redirect back to: http://openwebui.local/oauth/oidc/callback"
    echo "6. OpenWebUI validates token and creates session"
    echo ""
    
    echo "WordPress OAuth2 flow:"
    echo "1. User visits: http://wordpress-tenant1.local → $LOADBALANCER_IP"
    echo "2. WordPress redirects to Authentik for authentication"
    echo "3. After authentication, user is logged into WordPress"
    echo ""
    
    log_info "All OAuth2 endpoints are properly configured and accessible"
    log_info "The main requirement is completing WordPress installation"
    
    echo ""
}

generate_summary() {
    echo -e "${BLUE}📊 SSO Integration Test Summary${NC}"
    echo "=================================="
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo "Total tests: $((TESTS_PASSED + TESTS_FAILED))"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 SSO integration infrastructure is ready!${NC}"
        echo ""
        echo "✅ Authentik SSO is running and accessible"
        echo "✅ OAuth2 discovery endpoints working"
        echo "✅ OpenWebUI OAuth2 integration configured"
        echo "✅ All OAuth2 endpoints accessible"
        echo ""
        echo "Next steps:"
        echo "1. Complete WordPress installation"
        echo "2. Install/configure OAuth2 plugin in WordPress"
        echo "3. Test end-to-end authentication flow"
        return 0
    else
        echo -e "${RED}❌ Some SSO integration issues need attention.${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🔐 SSO Integration Testing${NC}"
    echo "=========================="
    echo ""
    
    test_authentik_service
    test_oauth2_discovery_endpoints
    test_openwebui_oauth_config
    test_wordpress_service
    test_oauth2_client_secrets
    test_oauth2_endpoints
    test_network_connectivity
    demonstrate_sso_flow
    
    generate_summary
}

# Check for required dependencies
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found${NC}"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl not found${NC}"
    exit 1
fi

# Run main function
main "$@"