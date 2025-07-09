#!/bin/bash

# WordPress-OpenWebUI Integration Health Test Script
# This script validates all components of the integration are working correctly

set -e

# Configuration
CLUSTER_ID="${CLUSTER_ID:-354372a8-cdfc-4c4c-814c-37effe9bf8a2}"
LOADBALANCER_IP="${LOADBALANCER_IP:-85.215.220.121}"
KUBECONFIG_FILE="${KUBECONFIG_FILE:-./kubeconfig.yaml}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

test_command() {
    local description="$1"
    local command="$2"
    local expected_pattern="$3"
    
    log_info "Testing: $description"
    
    if output=$(eval "$command" 2>&1); then
        if [ -n "$expected_pattern" ]; then
            if echo "$output" | grep -q "$expected_pattern"; then
                log_success "$description"
                return 0
            else
                log_error "$description - Output doesn't match expected pattern"
                echo "Expected pattern: $expected_pattern"
                echo "Actual output: $output"
                return 1
            fi
        else
            log_success "$description"
            return 0
        fi
    else
        log_error "$description - Command failed"
        echo "Error output: $output"
        return 1
    fi
}

# Main test functions
test_prerequisites() {
    echo -e "\n${BLUE}🔧 Testing Prerequisites${NC}"
    
    test_command "kubectl is installed" "kubectl version --client" "Client Version"
    test_command "curl is installed" "curl --version" "curl"
    test_command "jq is installed" "jq --version" "jq"
}

get_kubeconfig() {
    echo -e "\n${BLUE}🔐 Getting Kubernetes Configuration${NC}"
    
    if [ -z "$IONOS_TOKEN" ]; then
        log_error "IONOS_TOKEN environment variable not set"
        echo "Please set IONOS_TOKEN to your IONOS API token"
        exit 1
    fi
    
    log_info "Fetching kubeconfig from IONOS API"
    if curl -s -X GET \
        "https://api.ionos.com/cloudapi/v6/k8s/clusters/$CLUSTER_ID/kubeconfig" \
        -H "Authorization: Bearer $IONOS_TOKEN" \
        -H "Content-Type: application/json" \
        -o "$KUBECONFIG_FILE"; then
        log_success "Kubeconfig downloaded"
        export KUBECONFIG="$KUBECONFIG_FILE"
    else
        log_error "Failed to download kubeconfig"
        exit 1
    fi
}

test_cluster_connectivity() {
    echo -e "\n${BLUE}☸️  Testing Cluster Connectivity${NC}"
    
    test_command "Cluster connection" "kubectl cluster-info" "Kubernetes control plane"
    test_command "Node status" "kubectl get nodes --no-headers | grep Ready" "Ready"
}

test_pod_health() {
    echo -e "\n${BLUE}🏃 Testing Pod Health${NC}"
    
    log_info "Checking all pods across namespaces"
    
    # Get pods that are not Running or Succeeded
    failed_pods=$(kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | wc -l)
    
    if [ "$failed_pods" -eq 0 ]; then
        log_success "All pods are healthy"
        
        # Show summary of running pods
        log_info "Pod summary by namespace:"
        kubectl get pods -A --no-headers | awk '{print $1}' | sort | uniq -c | while read count namespace; do
            echo "  $namespace: $count pods"
        done
    else
        log_error "Found $failed_pods unhealthy pods"
        kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
    fi
}

test_loadbalancer() {
    echo -e "\n${BLUE}🌐 Testing LoadBalancer${NC}"
    
    test_command "LoadBalancer accessibility" "curl -I --max-time 10 http://$LOADBALANCER_IP/" "HTTP/"
}

test_wordpress() {
    echo -e "\n${BLUE}📝 Testing WordPress Service${NC}"
    
    test_command "WordPress homepage" \
        "curl -f --max-time 10 -H 'Host: wordpress-tenant1.local' http://$LOADBALANCER_IP/" \
        ""
    
    # Test WordPress REST API
    log_info "Testing WordPress REST API"
    posts_count=$(curl -s --max-time 10 -H "Host: wordpress-tenant1.local" \
        "http://$LOADBALANCER_IP/wp-json/wp/v2/posts" | jq length 2>/dev/null || echo "0")
    
    if [ "$posts_count" -gt 0 ]; then
        log_success "WordPress REST API ($posts_count posts available)"
    else
        log_error "WordPress REST API returned no posts or failed"
    fi
    
    # Test WordPress admin API endpoints
    test_command "WordPress API discovery" \
        "curl -s --max-time 10 -H 'Host: wordpress-tenant1.local' http://$LOADBALANCER_IP/wp-json/" \
        "wp/v2"
}

test_openwebui() {
    echo -e "\n${BLUE}🤖 Testing OpenWebUI Service${NC}"
    
    test_command "OpenWebUI homepage" \
        "curl -f --max-time 10 -H 'Host: openwebui.local' http://$LOADBALANCER_IP/" \
        ""
    
    # Test OAuth2 configuration
    log_info "Testing OAuth2 provider configuration"
    oauth_providers=$(curl -s --max-time 10 -H "Host: openwebui.local" \
        "http://$LOADBALANCER_IP/api/config" | jq -r '.oauth.providers | keys | length' 2>/dev/null || echo "0")
    
    if [ "$oauth_providers" -gt 0 ]; then
        log_success "OpenWebUI OAuth2 integration ($oauth_providers providers configured)"
        
        # Show configured providers
        providers=$(curl -s -H "Host: openwebui.local" \
            "http://$LOADBALANCER_IP/api/config" | jq -r '.oauth.providers' 2>/dev/null)
        echo "  Configured providers: $providers"
    else
        log_error "OpenWebUI OAuth2 providers not configured"
    fi
}

test_authentik() {
    echo -e "\n${BLUE}🔐 Testing Authentik SSO Service${NC}"
    
    # Test Authentik endpoint (should return 302 redirect for auth)
    log_info "Testing Authentik SSO response"
    status_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        -H "Host: authentik.local" "http://$LOADBALANCER_IP/")
    
    if [ "$status_code" = "302" ]; then
        log_success "Authentik SSO service (returns 302 redirect as expected)"
    else
        log_error "Authentik SSO unexpected response (got $status_code, expected 302)"
    fi
    
    # Test OIDC discovery
    log_info "Testing OIDC discovery endpoint"
    issuer=$(curl -s --max-time 10 -H "Host: authentik.local" \
        "http://$LOADBALANCER_IP/application/o/openwebui/.well-known/openid-configuration" | \
        jq -r '.issuer' 2>/dev/null)
    
    if [ "$issuer" != "null" ] && [ -n "$issuer" ]; then
        log_success "OIDC discovery endpoint (issuer: $issuer)"
    else
        log_error "OIDC discovery endpoint failed"
    fi
}

test_pipeline_service() {
    echo -e "\n${BLUE}⚙️  Testing Pipeline Service${NC}"
    
    log_info "Starting port-forward to pipeline service"
    kubectl port-forward -n admin-apps svc/wordpress-oauth-pipeline 9099:9099 &
    PORT_FORWARD_PID=$!
    
    # Wait for port-forward to be ready
    sleep 3
    
    # Test health endpoint
    if health_status=$(curl -s --max-time 5 http://localhost:9099/health | jq -r '.status' 2>/dev/null); then
        if [ "$health_status" = "healthy" ]; then
            log_success "Pipeline service health check"
            
            # Get pipeline info
            pipeline_info=$(curl -s http://localhost:9099/health | jq -r '.pipeline + " v" + .version' 2>/dev/null)
            echo "  Service: $pipeline_info"
        else
            log_error "Pipeline service health check failed (status: $health_status)"
        fi
    else
        log_error "Pipeline service unreachable"
    fi
    
    # Test authentication endpoint (should fail with auth error)
    if auth_response=$(curl -s http://localhost:9099/api/wordpress/connections -H "Authorization: Bearer test-token" 2>/dev/null); then
        if echo "$auth_response" | grep -q "Invalid authentication credentials"; then
            log_success "Pipeline service authentication validation"
        else
            log_warning "Pipeline service authentication response unexpected"
        fi
    else
        log_error "Pipeline service authentication endpoint failed"
    fi
    
    # Kill port-forward
    kill $PORT_FORWARD_PID 2>/dev/null || true
    wait $PORT_FORWARD_PID 2>/dev/null || true
}

test_oauth2_flow() {
    echo -e "\n${BLUE}🔄 Testing OAuth2 Integration Flow${NC}"
    
    # Test OAuth2 login endpoint (should return 302 with location header)
    log_info "Testing OAuth2 login redirect"
    if location_header=$(curl -s -I --max-time 10 -H "Host: openwebui.local" \
        "http://$LOADBALANCER_IP/oauth/oidc/login" | grep -i "location:" | head -1); then
        
        if [ -n "$location_header" ]; then
            log_success "OAuth2 redirect flow"
            echo "  Redirect: $(echo $location_header | tr -d '\r\n')"
        else
            log_error "OAuth2 login redirect not working (no location header)"
        fi
    else
        log_error "OAuth2 login endpoint failed"
    fi
}

test_performance() {
    echo -e "\n${BLUE}⚡ Testing Performance${NC}"
    
    # Test WordPress response time
    log_info "Measuring service response times"
    wp_time=$(curl -o /dev/null -s -w "%{time_total}" --max-time 15 \
        -H "Host: wordpress-tenant1.local" "http://$LOADBALANCER_IP/" 2>/dev/null || echo "timeout")
    
    # Test OpenWebUI response time  
    owu_time=$(curl -o /dev/null -s -w "%{time_total}" --max-time 15 \
        -H "Host: openwebui.local" "http://$LOADBALANCER_IP/" 2>/dev/null || echo "timeout")
    
    echo "  WordPress response time: ${wp_time}s"
    echo "  OpenWebUI response time: ${owu_time}s"
    
    # Check if response times are reasonable
    if [ "$wp_time" != "timeout" ] && (( $(echo "$wp_time < 10.0" | bc -l 2>/dev/null || echo 0) )); then
        log_success "WordPress response time acceptable"
    else
        log_warning "WordPress response time slow or timed out"
    fi
    
    if [ "$owu_time" != "timeout" ] && (( $(echo "$owu_time < 10.0" | bc -l 2>/dev/null || echo 0) )); then
        log_success "OpenWebUI response time acceptable"
    else
        log_warning "OpenWebUI response time slow or timed out"
    fi
}

generate_summary() {
    echo -e "\n${BLUE}📊 Test Summary${NC}"
    echo "=================================="
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo "Total tests: $((TESTS_PASSED + TESTS_FAILED))"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed! WordPress-OpenWebUI integration is healthy.${NC}"
        echo ""
        echo "Service URLs:"
        echo "  WordPress: http://$LOADBALANCER_IP (Host: wordpress-tenant1.local)"
        echo "  OpenWebUI: http://$LOADBALANCER_IP (Host: openwebui.local)"
        echo "  Authentik: http://$LOADBALANCER_IP (Host: authentik.local)"
        return 0
    else
        echo -e "${RED}❌ Some tests failed. Please check the integration setup.${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🧪 WordPress-OpenWebUI Integration Health Test${NC}"
    echo "=================================================="
    echo "Cluster: $CLUSTER_ID"
    echo "LoadBalancer: $LOADBALANCER_IP"
    echo ""
    
    test_prerequisites
    get_kubeconfig
    test_cluster_connectivity
    test_pod_health
    test_loadbalancer
    test_wordpress
    test_openwebui
    test_authentik
    test_pipeline_service
    test_oauth2_flow
    test_performance
    
    generate_summary
}

# Check for required environment variables
if [ -z "$IONOS_TOKEN" ]; then
    echo -e "${RED}Error: IONOS_TOKEN environment variable not set${NC}"
    echo "Please export your IONOS API token:"
    echo "  export IONOS_TOKEN=your_token_here"
    exit 1
fi

# Install bc if not available (for floating point arithmetic)
if ! command -v bc &> /dev/null; then
    log_warning "bc (calculator) not found - some performance checks may be skipped"
fi

# Run main function
main "$@"