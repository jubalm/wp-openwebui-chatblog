I have identified several pitfalls in our current GitHub Actions workflow that are causing recurring deployment failures and making debugging difficult. I will now implement a more robust, streamlined solution to address these issues.

### Analysis of Current Pitfalls

1.  **Fragile Kubeconfig Handling:** The current process of passing the `kubeconfig` as a build artifact between jobs is brittle and prone to failure.
2.  **Imperative Secret Injection:** Using `run` steps with `jq` and `kubectl` to create Kubernetes secrets is complex, error-prone, and not idempotent. The logic is split between Terraform and the CI script, making it hard to manage.
3.  **Lack of Local Debugging Parity:** The reliance on CI artifacts makes it difficult to replicate the CI environment locally, slowing down debugging cycles.

### Recommended Implementation Plan

To fix this, I will refactor the Terraform configuration and the GitHub workflow with the following steps:

1.  **Centralize Kubeconfig via `terraform_remote_state`:**
    *   I will modify the `platform` and `tenant` Terraform modules to fetch the Kubernetes cluster configuration directly from the `infrastructure` module's remote state using a `terraform_remote_state` data source.
    *   This will eliminate the need to pass the `kubeconfig` file as a CI artifact, making the modules self-sufficient.

2.  **Manage Kubernetes Secrets Declaratively with Terraform:**
    *   I will replace the imperative `kubectl` shell commands in the `deploy.yml` workflow with declarative `kubernetes_secret` resources in the `platform` Terraform module.
    *   Secrets for Authentik and OpenWebUI will be defined and managed directly within Terraform, ensuring the entire process is idempotent and version-controlled.

3.  **Simplify the CI Workflow:**
    *   Once the logic is moved into Terraform, I will remove the now-redundant `run` steps for secret injection and Kubeconfig handling from `deploy.yml`.

This new approach will create a more declarative, resilient, and maintainable CI/CD pipeline, preventing the kind of deployment loops we have been experiencing.