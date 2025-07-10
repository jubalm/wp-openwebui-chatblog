# Troubleshooting Common Deployment Failures

This document records common issues encountered during deployment and their resolutions.

## Authentik Helm Deployment Failure (Platform Module)

A series of issues caused the `helm_release.authentik` resource to fail during the `terraform apply` step in the `platform` module.

### 1. Problem: Database Connection Failure (Incorrect Chart)

- **Symptom:** The `authentik` pods would not become ready. Logs showed a DNS error indicating the application could not resolve the PostgreSQL database hostname.
- **Root Cause:** The `helm_release.authentik` resource in `terraform/platform/main.tf` was configured to use the generic public Helm chart from `https://charts.goauthentik.io/`. This chart expects specific environment variables (e.g., `AUTHENTIK_POSTGRESQL__HOST`) to configure the database connection. Our Terraform script, however, created a Kubernetes secret with different keys (e.g., `postgres_host`) and attempted to inject them using an `extraEnvFrom` block that was incompatible with the public chart's structure.
- **Solution:** The configuration was updated to use the project's local, customized Helm chart located at `charts/authentik`. This local chart is specifically designed to correctly map the keys from the Terraform-generated secret to the environment variables the Authentik application requires.

**Before (Incorrect):**

```terraform
resource "helm_release" "authentik" {
  name              = "authentik"
  namespace         = "admin-apps"
  repository        = "https://charts.goauthentik.io/"
  chart             = "authentik"
  # ... other properties
}
```

**After (Correct):**

```terraform
resource "helm_release" "authentik" {
  name              = "authentik"
  namespace         = "admin-apps"
  chart             = "../../charts/authentik" # Points to the local chart
  # ... other properties
}
```

### 2. Problem: Helm Chart Version Mismatch

- **Symptom:** After fixing the chart path, the deployment failed with the error: `Planned version is different from configured version`.
- **Root Cause:** The Terraform resource still contained a hardcoded `version` attribute. This conflicted with the `version` specified inside the local chart's `Chart.yaml` file.
- **Solution:** The `version` attribute was removed from the `helm_release.authentik` resource in `terraform/platform/main.tf`. When using a local chart, the version should be managed solely by the `Chart.yaml` file, making it the single source of truth.

### 3. Problem: Stale Helm Releases After Failure

- **Symptom:** After a failed deployment, subsequent attempts failed with the error: `cannot re-use a name that is still in use`.
- **Root Cause:** A failed `helm` operation can leave an orphaned release in the cluster. When Terraform tried to apply the configuration again, Helm refused to create a new release with the same name.
- **Solution:** The stale releases were manually removed from the cluster before re-running the deployment workflow.

### 4. Problem: Helm Lint Error

- **Symptom:** A persisting lint error on helm provider definition on terraform breaks the deployment when lint fixed.
- **Root Cause:** The deployment and official documentation otherwise contradicts the lint error so it may be an updated (or outdated) VSCode extension reporting incorrectly.
- **Solution:** Ignore Terraform Error as this may be a bug [Helm Provider Docs](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)

**Cleanup Commands:**

```bash
# Ensure KUBECONFIG is set correctly
helm uninstall authentik -n admin-apps
helm uninstall openwebui -n admin-apps
```

## Terraform-Helm Integration Issues

### 5. Problem: State Ownership Conflicts Between Terraform and Helm

- **Symptom:** Deployment failures with errors like "cannot re-use a name that is still in use" and "context deadline exceeded"
- **Root Cause:** Terraform and Helm were fighting over resource ownership. Resources created by Helm releases were conflicting with Terraform-managed resources.
- **Solution:** Implemented clear tool boundaries and state reconciliation. See [Terraform-Helm Integration Guide](terraform-helm-integration.md) for detailed patterns.

### 6. Problem: Circular Dependency Between Deployment and PVC

- **Symptom:** Terraform plan fails with "Error: Cycle: kubernetes_deployment.wordpress_oauth_pipeline, kubernetes_persistent_volume_claim.wordpress_oauth_data"
- **Root Cause:** The PVC had a `depends_on` referencing the deployment that consumes it, creating a circular dependency.
- **Solution:** Removed the incorrect `depends_on` from the PVC. Terraform automatically handles the correct creation order based on resource references.

### 7. Problem: Stale Plan After State Import

- **Symptom:** "Error: Saved plan is stale" during terraform apply after importing resources
- **Root Cause:** State import operations were modifying the state after the plan was created, invalidating the plan.
- **Solution:** Moved state validation and import logic to the plan phase in the GitHub Actions workflow.

For comprehensive integration patterns, see the [Terraform-Helm Integration Guide](terraform-helm-integration.md).
