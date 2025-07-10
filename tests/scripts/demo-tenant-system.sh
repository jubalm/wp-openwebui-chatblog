#!/bin/bash

# Tenant System Demo Script
# Shows how to use the multi-tenant WordPress-OpenWebUI platform

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-$PROJECT_ROOT/kubeconfig.yaml}"
LOADBALANCER_IP="${LOADBALANCER_IP:-}"
CLUSTER_ID="${CLUSTER_ID:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_demo() {
    echo -e "${CYAN}🎬 $1${NC}"
}

# Set kubeconfig
export KUBECONFIG="$KUBECONFIG_PATH"

# Demo functions
demo_intro() {
    clear
    echo -e "${CYAN}
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    🚀 WordPress-OpenWebUI Multi-Tenant Platform Demo        ║
║                                                              ║
║    This demo shows how to manage multiple WordPress         ║
║    tenants with automated provisioning, OAuth2 integration, ║
║    and content automation capabilities.                     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
${NC}"
    echo ""
    log_info "Press Enter to start the demo..."
    read
}

demo_current_status() {
    log_section "Current Platform Status"
    echo ""
    
    log_info "Cluster: $CLUSTER_ID"
    log_info "LoadBalancer: $LOADBALANCER_IP"
    echo ""
    
    log_demo "🏗️ Checking infrastructure components..."
    
    # Check namespaces
    echo "Available namespaces:"
    kubectl get namespaces | grep -E "(admin-apps|tenant|ingress)" || true
    echo ""
    
    # Check existing tenants
    echo "Current tenants:"
    kubectl get namespaces -l "app.kubernetes.io/name=wordpress-tenant" -o custom-columns="TENANT:.metadata.name,DISPLAY_NAME:.metadata.annotations.tenant\.wp-openwebui\.io/display-name,TIER:.metadata.labels.tier,CREATED:.metadata.creationTimestamp" --no-headers 2>/dev/null || echo "No properly labeled tenants found"
    echo ""
    
    # Check admin apps
    log_demo "🔧 Admin platform services:"
    kubectl get pods -n admin-apps | grep -E "(authentik|openwebui|wordpress-oauth)" | head -5 || echo "Admin services not found"
    echo ""
    
    log_info "Press Enter to continue..."
    read
}

demo_tenant_operations() {
    log_section "Tenant Management Operations"
    echo ""
    
    log_demo "📋 Available tenant management commands:"
    echo ""
    echo "# List all tenants"
    echo "  ./scripts/tenant-management.sh list"
    echo ""
    echo "# Create a new tenant (example)"
    echo "  ./scripts/tenant-management.sh create demo-company 'Demo Company Inc' admin@demo.com pro"
    echo ""
    echo "# Get tenant details"
    echo "  ./scripts/tenant-management.sh details tenant1"
    echo ""
    echo "# Scale tenant to different tier"
    echo "  ./scripts/tenant-management.sh scale tenant1 pro"
    echo ""
    echo "# Test tenant functionality"
    echo "  ./scripts/tenant-management.sh test tenant1"
    echo ""
    
    log_demo "🧪 Testing current tenant1..."
    echo ""
    
    # Test WordPress access
    echo "Testing WordPress accessibility:"
    if curl -s -H "Host: wordpress-tenant1.local" "http://$LOADBALANCER_IP/" | grep -q "WordPress\\|wp-"; then
        log_success "tenant1 WordPress is accessible at http://wordpress-tenant1.local"
    else
        log_warning "tenant1 WordPress returned unexpected response"
    fi
    
    # Test REST API
    echo ""
    echo "Testing WordPress REST API:"
    if curl -s -H "Host: wordpress-tenant1.local" "http://$LOADBALANCER_IP/wp-json/wp/v2/" | grep -q "namespaces"; then
        log_success "tenant1 WordPress REST API is working"
    else
        log_warning "tenant1 WordPress REST API not responding correctly"
    fi
    
    echo ""
    log_info "Press Enter to continue..."
    read
}

demo_tier_comparison() {
    log_section "Tenant Tier Comparison"
    echo ""
    
    log_demo "💰 Available tiers and their features:"
    echo ""
    
    cat << 'EOF'
┌─────────────────┬─────────────┬─────────────┬─────────────────┐
│     Feature     │    Free     │     Pro     │   Enterprise    │
├─────────────────┼─────────────┼─────────────┼─────────────────┤
│ CPU Limit       │    500m     │   2000m     │     4000m       │
│ Memory Limit    │   512Mi     │    2Gi      │      4Gi        │
│ Storage         │    5Gi      │    50Gi     │     200Gi       │
│ Database        │ 1c/2GB RAM  │ 2c/4GB RAM  │   4c/8GB RAM    │
│ SSO             │     ❌      │     ✅      │       ✅        │
│ Custom Plugins  │     ❌      │     ✅      │       ✅        │
│ Analytics       │     ❌      │     ✅      │       ✅        │
│ Custom Domains  │     ❌      │     ❌      │       ✅        │
│ Support Level   │ Community   │  Standard   │    Premium      │
└─────────────────┴─────────────┴─────────────┴─────────────────┘
EOF
    
    echo ""
    log_demo "🎯 Content automation is available on all tiers!"
    echo ""
    
    log_info "Press Enter to continue..."
    read
}

demo_content_automation() {
    log_section "Content Automation Features"
    echo ""
    
    log_demo "🤖 WordPress ↔ OpenWebUI Content Integration:"
    echo ""
    
    echo "Available features:"
    echo "  ✅ Natural language publishing triggers"
    echo "  ✅ Auto-generated excerpts and tags"
    echo "  ✅ SEO optimization"
    echo "  ✅ Workflow management with retry logic"
    echo "  ✅ Multiple content types (blog, article, tutorial, FAQ, docs)"
    echo ""
    
    log_demo "📝 Example usage in OpenWebUI:"
    echo ""
    echo "User: \"Please publish this blog post about AI automation to WordPress\""
    echo ""
    echo "Pipeline response:"
    echo "🚀 WordPress Publishing Pipeline Activated"
    echo ""
    echo "Title: AI Automation in Modern Workflows"
    echo "Content Type: blog_post"
    echo "Auto-publish: No (Draft)"
    echo ""
    echo "✅ Publishing Workflow Created Successfully!"
    echo "Workflow ID: abc123-def456-ghi789"
    echo "Status: processing"
    echo ""
    
    # Check if pipeline service is running
    echo "Checking pipeline service status:"
    if kubectl get pods -n admin-apps | grep -q "wordpress-oauth-pipeline"; then
        log_success "Content automation pipeline service is deployed"
    else
        log_warning "Content automation pipeline service not found"
    fi
    
    echo ""
    log_info "Press Enter to continue..."
    read
}

demo_architecture() {
    log_section "Multi-Tenant Architecture"
    echo ""
    
    log_demo "🏗️ Platform Architecture:"
    echo ""
    
    cat << 'EOF'
┌─────────────────────────────────────────────────────────────┐
│                    IONOS Cloud Infrastructure               │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │     MKS     │  │ PostgreSQL  │  │     MariaDB         │  │
│  │   Cluster   │  │   Cluster   │  │   (per tenant)      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   LoadBalancer    │
                    │  85.215.220.121   │
                    └─────────┬─────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
   ┌────▼────┐         ┌─────▼─────┐         ┌─────▼─────┐
   │ tenant1 │         │tenant2    │         │ tenantN   │
   │namespace│         │namespace  │   ...   │namespace  │
   │         │         │           │         │           │
   │WordPress│         │WordPress  │         │WordPress  │
   │Instance │         │Instance   │         │Instance   │
   └─────────┘         └───────────┘         └───────────┘
                              │
                    ┌─────────▼─────────┐
                    │   admin-apps      │
                    │   namespace       │
                    │                   │
                    │ ┌───────────────┐ │
                    │ │ Authentik SSO │ │
                    │ │   OpenWebUI   │ │
                    │ │   Pipelines   │ │
                    │ └───────────────┘ │
                    └───────────────────┘
EOF
    
    echo ""
    log_demo "🔐 Key features:"
    echo "  • Namespace isolation per tenant"
    echo "  • Dedicated MariaDB clusters"
    echo "  • Shared OAuth2 authentication"
    echo "  • Resource quotas and network policies"
    echo "  • Automated provisioning and scaling"
    echo ""
    
    log_info "Press Enter to continue..."
    read
}

demo_access_urls() {
    log_section "Access Information"
    echo ""
    
    log_demo "🌐 Service URLs (all via LoadBalancer $LOADBALANCER_IP):"
    echo ""
    
    echo "Current tenant1:"
    echo "  WordPress: http://wordpress-tenant1.local → $LOADBALANCER_IP"
    echo "  Status: $(curl -s -o /dev/null -w "%{http_code}" -H "Host: wordpress-tenant1.local" "http://$LOADBALANCER_IP/" || echo "Error")"
    echo ""
    
    echo "Platform services:"
    echo "  OpenWebUI: http://openwebui.local → $LOADBALANCER_IP"
    echo "  Authentik SSO: http://authentik.local → $LOADBALANCER_IP"
    echo ""
    
    echo "New tenants (examples):"
    echo "  http://wordpress-demo-company.local → $LOADBALANCER_IP"
    echo "  http://wordpress-startup-xyz.local → $LOADBALANCER_IP"
    echo "  http://wordpress-enterprise-corp.local → $LOADBALANCER_IP"
    echo ""
    
    log_demo "📱 To test locally, add to /etc/hosts:"
    echo "$LOADBALANCER_IP wordpress-tenant1.local"
    echo "$LOADBALANCER_IP openwebui.local"
    echo "$LOADBALANCER_IP authentik.local"
    echo ""
    
    log_info "Press Enter to continue..."
    read
}

demo_next_steps() {
    log_section "Next Steps & Getting Started"
    echo ""
    
    log_demo "🚀 Ready to create your first tenant? Here's how:"
    echo ""
    
    echo "1. Create a new tenant:"
    echo "   ./scripts/tenant-management.sh create my-company 'My Company Inc' admin@mycompany.com pro"
    echo ""
    
    echo "2. Wait for deployment (usually 2-3 minutes)"
    echo ""
    
    echo "3. Test the new tenant:"
    echo "   ./scripts/tenant-management.sh test my-company"
    echo ""
    
    echo "4. Access your WordPress:"
    echo "   http://wordpress-my-company.local (add to /etc/hosts)"
    echo ""
    
    echo "5. Configure content automation in OpenWebUI"
    echo ""
    
    log_demo "📚 Documentation:"
    echo "  • Architecture: docs/MULTI_TENANT_ARCHITECTURE.md"
    echo "  • Quick Start: docs/TENANT_PROVISIONING_QUICKSTART.md"
    echo "  • Content Automation: docs/CONTENT_AUTOMATION_GUIDE.md"
    echo ""
    
    log_demo "🛠️ Management commands:"
    echo "  • List tenants: ./scripts/tenant-management.sh list"
    echo "  • Scale tenant: ./scripts/tenant-management.sh scale <tenant> <tier>"
    echo "  • Delete tenant: ./scripts/tenant-management.sh delete <tenant> --confirm"
    echo ""
    
    log_success "The multi-tenant WordPress-OpenWebUI platform is ready!"
    echo ""
}

# Main demo execution
main() {
    demo_intro
    demo_current_status
    demo_tenant_operations
    demo_tier_comparison
    demo_content_automation
    demo_architecture
    demo_access_urls
    demo_next_steps
    
    echo -e "${GREEN}
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                    🎉 Demo Complete!                        ║
║                                                              ║
║   The multi-tenant WordPress-OpenWebUI platform is ready    ║
║   for production use with automated provisioning, content   ║
║   automation, and enterprise-grade scaling capabilities.    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
${NC}"
}

# Run the demo
main "$@"