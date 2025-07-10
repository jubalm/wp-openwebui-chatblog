# Terraform-Helm Integration Best Practices

This document outlines the proper integration patterns between Terraform and Helm to avoid common state management conflicts.

## Understanding Tool Boundaries

### Tool Responsibilities

**Terraform owns:**
- Infrastructure provisioning (clusters, databases, networks)
- Kubernetes resources that configure the platform
- State management for all resources it creates
- Resource dependencies and ordering

**Helm owns:**
- Application deployment and lifecycle
- Chart-specific resources (ConfigMaps, Secrets created by charts)
- Application-specific configuration
- Rolling updates and application versioning

### Integration Challenges Resolved

During deployment, we encountered several integration boundary issues between Terraform and Helm:

1. **State Ownership Conflicts**: Resources created by Helm releases were conflicting with Terraform-managed resources
2. **Circular Dependencies**: Incorrect dependency declarations between PVCs and Deployments
3. **Stale Plan Errors**: State modifications after plan creation causing apply failures

## Best Practices Implementation

### 1. Helm Release Management

When managing Helm releases with Terraform, use the following pattern to handle existing releases gracefully:

```hcl
resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.10.1"
  
  # Handle existing releases gracefully
  replace = true
  
  lifecycle {
    # Prevent accidental deletion of critical infrastructure
    prevent_destroy = true
    # Ignore changes that don't affect core functionality
    ignore_changes = [
      version,  # Allow version drift
      metadata
    ]
  }
}
```

### 2. Resource Dependency Ordering

Ensure proper dependency ordering without creating circular dependencies:

```hcl
# Deployment depends on namespace and secrets
resource "kubernetes_deployment" "wordpress_oauth_pipeline" {
  depends_on = [
    kubernetes_namespace.admin_apps,
    kubernetes_secret.wordpress_oauth_env
  ]
  # ... deployment configuration
}

# PVC should NOT depend on the deployment that consumes it
resource "kubernetes_persistent_volume_claim" "wordpress_oauth_data" {
  metadata {
    name      = "wordpress-oauth-data"
    namespace = kubernetes_namespace.admin_apps.metadata[0].name
  }
  # ... PVC configuration
}
```

### 3. State Import Strategy

To prevent "already exists" errors during deployment, implement state validation and import logic:

```bash
# Function to check if resource exists in state
check_state() {
  terraform state show "$1" >/dev/null 2>&1
}

# Function to import resource if it exists in cluster but not in state
import_if_exists() {
  local resource_type="$1"
  local resource_name="$2"
  local import_id="$3"
  
  if ! check_state "$resource_type.$resource_name"; then
    echo "Checking if $resource_type.$resource_name exists in cluster..."
    
    # Try to import the resource
    if terraform import "$resource_type.$resource_name" "$import_id" 2>/dev/null; then
      echo "✅ Imported existing $resource_type.$resource_name"
    else
      echo "ℹ️  $resource_type.$resource_name not found in cluster - will be created"
    fi
  else
    echo "✅ $resource_type.$resource_name already in state"
  fi
}
```

### 4. Deployment Strategy for Stateful Workloads

For deployments with persistent volume claims, use the `Recreate` strategy to avoid multi-attach errors:

```hcl
spec {
  replicas = 1
  
  strategy {
    type = "Recreate"  # Ensures old pod is terminated before new one is created
  }
  # ... rest of deployment spec
}
```

## Common Pitfalls to Avoid

1. **Don't create circular dependencies**: PVCs should not depend on deployments that consume them
2. **Don't modify state after planning**: Import operations should happen during the plan phase
3. **Don't fight tool boundaries**: Let Helm manage application-specific resources
4. **Don't ignore existing resources**: Always check and import existing resources before creating

## Workflow Integration

The GitHub Actions workflow implements these patterns:

1. **Infrastructure Phase**: Creates the base cluster and networking
2. **Platform Phase**: 
   - Imports existing resources during plan stage
   - Applies changes with proper dependency ordering
3. **Tenant Phase**: Deploys application instances
4. **Post-Deployment**: Validates deployment health

## Key Takeaways

- Terraform and Helm are complementary tools with clear boundaries
- State conflicts arise when boundaries are violated
- Proper import logic prevents "already exists" errors
- Dependency ordering must respect Kubernetes resource relationships
- The `replace` flag in Helm releases handles existing deployments gracefully

This integration pattern ensures "blissful one-shot deployments" by respecting tool boundaries and handling state conflicts appropriately.