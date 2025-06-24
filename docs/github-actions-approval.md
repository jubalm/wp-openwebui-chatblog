# Enabling Manual Approval for Terraform Apply in GitHub Actions

To require manual approval before running `terraform apply` in your GitHub Actions workflows, use GitHub Environments with required reviewers. This is supported on all GitHub plans.

## How it works
- The workflow's `apply` job references an `environment` (e.g., `platform-approval`).
- When the workflow runs, it will pause and wait for a reviewer to approve before proceeding with the `apply` job.

## Steps to Enable Manual Approval

1. **Go to your repository on GitHub.**
2. Click on **Settings** > **Environments** (in the left sidebar).
3. Click **New environment** and enter the name (e.g., `platform-approval`, `infrastructure-approval`, or `tenant-approval`).
4. After creating the environment, click on it to open its settings.
5. Under **Required reviewers**, add the GitHub users or teams who should approve deployments.
6. Save your changes.
7. In your workflow YAML, ensure the `apply` job includes the line (uncomment if needed):
   ```yaml
   environment: platform-approval  # or infrastructure-approval, tenant-approval
   ```
8. Commit and push your workflow file.

## Example Workflow Snippet
```yaml
apply:
  needs: plan
  runs-on: ubuntu-latest
  environment: platform-approval  # This triggers the manual approval step
  steps:
    - uses: actions/checkout@v4
    - name: Set up Terraform
      uses: hashicorp/setup-terraform@v3
    - name: Terraform Init
      run: terraform -chdir=terraform/platform init
    - name: Terraform Apply
      run: terraform -chdir=terraform/platform apply -auto-approve
```

**Result:**
- When a workflow run reaches the `apply` job, it will pause and require a reviewer to approve the deployment in the GitHub UI before proceeding.

For more details, see the [GitHub documentation on environments and required reviewers](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#required-reviewers). 