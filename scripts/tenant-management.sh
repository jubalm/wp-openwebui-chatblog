#!/bin/bash

# Multi-Tenant Management Script
# Provides commands for managing WordPress tenants in the platform

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/terraform/tenant"
KUBECONFIG_PATH="$PROJECT_ROOT/kubeconfig.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Utility functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_section() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    local missing_tools=()
    
    for tool in terraform kubectl jq yq; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    if [ ! -f "$KUBECONFIG_PATH" ]; then
        log_error "Kubeconfig not found at $KUBECONFIG_PATH"
        exit 1
    fi
    
    export KUBECONFIG="$KUBECONFIG_PATH"
}

# List all tenants
list_tenants() {
    log_section "Listing all tenants"
    
    echo "Active tenants:"
    kubectl get namespaces -l "app.kubernetes.io/name=wordpress-tenant" -o custom-columns="TENANT:.metadata.name,DISPLAY_NAME:.metadata.annotations.tenant\.wp-openwebui\.io/display-name,TIER:.metadata.labels.tier,CREATED:.metadata.creationTimestamp" --no-headers
    
    echo ""
    echo "Tenant databases:"
    cd "$TERRAFORM_DIR"
    terraform output -json mariadb_connections 2>/dev/null | jq -r 'keys[]' 2>/dev/null || echo "No database information available"
}

# Get tenant details
get_tenant_details() {
    local tenant_id="$1"
    
    if [ -z "$tenant_id" ]; then
        log_error "Tenant ID is required"
        return 1
    fi
    
    log_section "Getting details for tenant: $tenant_id"
    
    # Check if tenant exists
    if ! kubectl get namespace "$tenant_id" &>/dev/null; then
        log_error "Tenant '$tenant_id' not found"
        return 1
    fi
    
    # Namespace information
    echo "=== Namespace Information ==="
    kubectl get namespace "$tenant_id" -o yaml | yq eval '.metadata | {name, labels, annotations, creationTimestamp}' -
    
    echo ""
    echo "=== Resource Quota ==="
    kubectl get resourcequota -n "$tenant_id" -o yaml 2>/dev/null | yq eval '.items[0].status' - || echo "No resource quota found"
    
    echo ""
    echo "=== Pods ==="
    kubectl get pods -n "$tenant_id" -o wide
    
    echo ""
    echo "=== Services ==="
    kubectl get services -n "$tenant_id"
    
    echo ""
    echo "=== Ingress ==="
    kubectl get ingress -n "$tenant_id"
    
    echo ""
    echo "=== Persistent Volumes ==="
    kubectl get pvc -n "$tenant_id"
    
    echo ""
    echo "=== Tenant Configuration ==="
    kubectl get configmap tenant-config -n "$tenant_id" -o yaml 2>/dev/null | yq eval '.data."tenant.json"' - | jq . || echo "No tenant configuration found"
}

# Create a new tenant
create_tenant() {
    local tenant_id="$1"
    local display_name="$2"
    local admin_email="$3"
    local tier="${4:-free}"
    
    if [ -z "$tenant_id" ] || [ -z "$display_name" ] || [ -z "$admin_email" ]; then
        log_error "Usage: create_tenant <tenant_id> <display_name> <admin_email> [tier]"
        log_info "Example: create_tenant acme-corp 'ACME Corporation' admin@acme.com pro"
        return 1
    fi
    
    # Validate tenant ID format
    if ! [[ "$tenant_id" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]] || [ ${#tenant_id} -gt 20 ]; then
        log_error "Tenant ID must be lowercase alphanumeric with hyphens, max 20 characters"
        return 1
    fi
    
    # Validate tier
    if ! [[ "$tier" =~ ^(free|pro|enterprise)$ ]]; then
        log_error "Tier must be one of: free, pro, enterprise"
        return 1
    fi
    
    log_section "Creating tenant: $tenant_id"
    
    # Check if tenant already exists
    if kubectl get namespace "$tenant_id" &>/dev/null; then
        log_error "Tenant '$tenant_id' already exists"
        return 1
    fi
    
    # Create Terraform variables file for the new tenant
    local tenant_tfvars="$TERRAFORM_DIR/tenant-$tenant_id.tfvars"
    
    cat > "$tenant_tfvars" << EOF
wordpress_tenants = {
  "$tenant_id" = {
    display_name   = "$display_name"
    admin_user     = "${tenant_id}-admin"
    admin_password = "$(openssl rand -base64 16)"
    admin_email    = "$admin_email"
    tier          = "$tier"
  }
}
EOF
    
    log_info "Created tenant configuration: $tenant_tfvars"
    
    # Apply Terraform configuration
    cd "$TERRAFORM_DIR"
    log_info "Applying Terraform configuration..."
    
    if terraform plan -var-file="$tenant_tfvars" -out="tenant-$tenant_id.plan"; then
        if terraform apply "tenant-$tenant_id.plan"; then
            log_success "Tenant '$tenant_id' created successfully"
            
            # Wait for deployment to be ready
            log_info "Waiting for WordPress deployment to be ready..."
            kubectl wait --for=condition=available --timeout=300s deployment/wordpress-$tenant_id -n "$tenant_id"
            
            # Show tenant details
            get_tenant_details "$tenant_id"
            
            # Show access information
            echo ""
            log_success "Tenant Access Information:"
            echo "URL: http://wordpress-$tenant_id.local"
            echo "Admin User: ${tenant_id}-admin"
            echo "Admin Email: $admin_email"
            echo "Tier: $tier"
            
        else
            log_error "Failed to apply Terraform configuration"
            rm -f "$tenant_tfvars" "tenant-$tenant_id.plan"
            return 1
        fi
    else
        log_error "Terraform plan failed"
        rm -f "$tenant_tfvars"
        return 1
    fi
    
    # Clean up plan file
    rm -f "tenant-$tenant_id.plan"
}

# Delete a tenant
delete_tenant() {
    local tenant_id="$1"
    local confirm="$2"
    
    if [ -z "$tenant_id" ]; then
        log_error "Tenant ID is required"
        return 1
    fi
    
    if [ "$confirm" != "--confirm" ]; then
        log_warning "This will permanently delete tenant '$tenant_id' and all its data!"
        log_warning "To confirm, run: $0 delete $tenant_id --confirm"
        return 1
    fi
    
    log_section "Deleting tenant: $tenant_id"
    
    # Check if tenant exists
    if ! kubectl get namespace "$tenant_id" &>/dev/null; then
        log_error "Tenant '$tenant_id' not found"
        return 1
    fi
    
    # Delete via Terraform (this will handle MariaDB cleanup)
    cd "$TERRAFORM_DIR"
    
    local tenant_tfvars="$TERRAFORM_DIR/tenant-$tenant_id.tfvars"
    if [ -f "$tenant_tfvars" ]; then
        log_info "Destroying Terraform resources..."
        terraform destroy -var-file="$tenant_tfvars" -auto-approve
        rm -f "$tenant_tfvars"
    else
        log_warning "Tenant configuration file not found, manually deleting Kubernetes resources"
        kubectl delete namespace "$tenant_id" --ignore-not-found=true
    fi
    
    log_success "Tenant '$tenant_id' deleted successfully"
}

# Scale tenant resources
scale_tenant() {
    local tenant_id="$1"
    local tier="$2"
    
    if [ -z "$tenant_id" ] || [ -z "$tier" ]; then
        log_error "Usage: scale_tenant <tenant_id> <new_tier>"
        log_info "Available tiers: free, pro, enterprise"
        return 1
    fi
    
    if ! [[ "$tier" =~ ^(free|pro|enterprise)$ ]]; then
        log_error "Tier must be one of: free, pro, enterprise"
        return 1
    fi
    
    log_section "Scaling tenant '$tenant_id' to tier '$tier'"
    
    # Check if tenant exists
    if ! kubectl get namespace "$tenant_id" &>/dev/null; then
        log_error "Tenant '$tenant_id' not found"
        return 1
    fi
    
    # Update tenant configuration
    local tenant_tfvars="$TERRAFORM_DIR/tenant-$tenant_id.tfvars"
    if [ ! -f "$tenant_tfvars" ]; then
        log_error "Tenant configuration file not found: $tenant_tfvars"
        return 1
    fi
    
    # Update tier in tfvars file
    sed -i.bak "s/tier *= *\"[^\"]*\"/tier = \"$tier\"/" "$tenant_tfvars"
    
    # Apply changes
    cd "$TERRAFORM_DIR"
    log_info "Applying scaling changes..."
    
    if terraform plan -var-file="$tenant_tfvars" -out="scale-$tenant_id.plan"; then
        if terraform apply "scale-$tenant_id.plan"; then
            log_success "Tenant '$tenant_id' scaled to tier '$tier' successfully"
            
            # Update namespace label
            kubectl label namespace "$tenant_id" tier="$tier" --overwrite
            
            rm -f "scale-$tenant_id.plan"
        else
            log_error "Failed to apply scaling changes"
            mv "$tenant_tfvars.bak" "$tenant_tfvars"
            rm -f "scale-$tenant_id.plan"
            return 1
        fi
    else
        log_error "Terraform plan failed"
        mv "$tenant_tfvars.bak" "$tenant_tfvars"
        return 1
    fi
    
    rm -f "$tenant_tfvars.bak"
}

# Get tenant resource usage
get_tenant_usage() {
    local tenant_id="$1"
    
    if [ -z "$tenant_id" ]; then
        log_error "Tenant ID is required"
        return 1
    fi
    
    if ! kubectl get namespace "$tenant_id" &>/dev/null; then
        log_error "Tenant '$tenant_id' not found"
        return 1
    fi
    
    log_section "Resource usage for tenant: $tenant_id"
    
    # CPU and Memory usage
    echo "=== Resource Usage ==="
    kubectl top pods -n "$tenant_id" 2>/dev/null || log_warning "Metrics server not available"
    
    # Storage usage
    echo ""
    echo "=== Storage Usage ==="
    kubectl get pvc -n "$tenant_id" -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage,USED:.status.capacity.storage"
    
    # Resource quota status
    echo ""
    echo "=== Resource Quota Status ==="
    kubectl get resourcequota -n "$tenant_id" -o yaml 2>/dev/null | yq eval '.items[0].status | {hard, used}' - || echo "No resource quota found"
}

# Test tenant functionality
test_tenant() {
    local tenant_id="$1"
    
    if [ -z "$tenant_id" ]; then
        log_error "Tenant ID is required"
        return 1
    fi
    
    log_section "Testing tenant: $tenant_id"
    
    # Check if tenant exists
    if ! kubectl get namespace "$tenant_id" &>/dev/null; then
        log_error "Tenant '$tenant_id' not found"
        return 1
    fi
    
    # Test WordPress availability
    echo "=== WordPress Health Check ==="
    local loadbalancer_ip=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    if [ -n "$loadbalancer_ip" ]; then
        if curl -s -H "Host: wordpress-$tenant_id.local" "http://$loadbalancer_ip/" | grep -q "WordPress"; then
            log_success "WordPress is accessible"
        else
            log_error "WordPress is not responding correctly"
        fi
        
        # Test WordPress REST API
        if curl -s -H "Host: wordpress-$tenant_id.local" "http://$loadbalancer_ip/wp-json/wp/v2/" | grep -q "namespaces"; then
            log_success "WordPress REST API is working"
        else
            log_error "WordPress REST API is not working"
        fi
    else
        log_warning "LoadBalancer IP not available"
    fi
    
    # Check pod status
    echo ""
    echo "=== Pod Status ==="
    kubectl get pods -n "$tenant_id" -o wide
    
    # Check logs for errors
    echo ""
    echo "=== Recent Logs (last 10 lines) ==="
    kubectl logs -n "$tenant_id" deployment/wordpress-$tenant_id --tail=10 || log_warning "Could not retrieve logs"
}

# Show usage information
show_usage() {
    echo "Multi-Tenant Management Script"
    echo ""
    echo "Usage: $0 <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  list                              List all tenants"
    echo "  details <tenant_id>               Get detailed information about a tenant"
    echo "  create <tenant_id> <display_name> <admin_email> [tier]"
    echo "                                    Create a new tenant"
    echo "  delete <tenant_id> --confirm      Delete a tenant (requires confirmation)"
    echo "  scale <tenant_id> <new_tier>      Scale tenant to a different tier"
    echo "  usage <tenant_id>                 Show resource usage for a tenant"
    echo "  test <tenant_id>                  Test tenant functionality"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 create acme-corp 'ACME Corporation' admin@acme.com pro"
    echo "  $0 details acme-corp"
    echo "  $0 scale acme-corp enterprise"
    echo "  $0 delete acme-corp --confirm"
    echo ""
    echo "Tiers: free, pro, enterprise"
}

# Main execution
main() {
    check_prerequisites
    
    case "${1:-}" in
        list)
            list_tenants
            ;;
        details)
            get_tenant_details "$2"
            ;;
        create)
            create_tenant "$2" "$3" "$4" "$5"
            ;;
        delete)
            delete_tenant "$2" "$3"
            ;;
        scale)
            scale_tenant "$2" "$3"
            ;;
        usage)
            get_tenant_usage "$2"
            ;;
        test)
            test_tenant "$2"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: ${1:-}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"