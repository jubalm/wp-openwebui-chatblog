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

**Cleanup Commands:**
```bash
# Ensure KUBECONFIG is set correctly
helm uninstall authentik -n admin-apps
helm uninstall openwebui -n admin-apps
```
