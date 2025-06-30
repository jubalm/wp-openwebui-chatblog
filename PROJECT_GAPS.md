# Project Gaps & Implementation Checklist

This document outlines the remaining work required to complete the PoC as defined in `docs/product-requirements.md`.

### 1. WordPress Deployment

- [x] Create a Helm chart for the WordPress deployment in the `charts/wordpress` directory.
  - [x] Define `Deployment` and `Service` resources.
  - [x] Configure a `PersistentVolumeClaim` for WordPress data (`/var/www/html`).
  - [x] Create an `Ingress` resource for external access.
  - [x] Use a `values.yaml` file to manage configurable parameters (image tag, tenant name, etc.).
- [ ] Update the `docker/wordpress/Dockerfile` to include the necessary plugins:
  - [x] `wordpress-mcp` plugin (v0.2.2).
  - [x] An open-source OIDC client plugin (e.g., "OpenID Connect Generic Client by daggerhart").
  - [ ] The custom plugin for OpenWebUI integration (once developed).
- [ ] Build and push the custom WordPress Docker image to a container registry.
- [x] Update `terraform/tenant/main.tf` to deploy the WordPress Helm chart for each tenant.

### 2. Integration & Secrets Automation (GitHub Actions)

- [ ] Create a GitHub Actions workflow (`.github/workflows/deploy.yml`) to automate the deployment.
- [ ] **Terraform to Kubernetes Secret Injection:**
  - [ ] The workflow should run `terraform apply` for the `infrastructure`, `platform`, and `tenant` modules.
  - [ ] The workflow should capture the Terraform outputs (database credentials, etc.).
  - [ ] The workflow should use `kubectl` to create or update the Kubernetes Secrets (`authentik-env-secrets`, `openwebui-env-secrets`, and a new one for each WordPress tenant) with the values from the Terraform outputs.
- [ ] **Secrets Management:**
  - [ ] Ensure all sensitive values (`IONOS_TOKEN`, etc.) are stored as GitHub Actions secrets and used in the workflow.
  - [ ] Remove any hardcoded passwords from the Terraform files (e.g., the MariaDB password in `terraform/tenant/main.tf`).

### 3. Application Configuration (Post-Deployment)

- [ ] **Authentik:**
  - [ ] Plan a strategy to configure Authentik post-deployment (e.g., using the Authentik API via a script in the GitHub Actions workflow).
  - [ ] Configure Authentik as an OIDC provider.
  - [ ] Create OIDC client applications for OpenWebUI and each WordPress tenant.
- [ ] **OpenWebUI:**
  - [ ] Configure OpenWebUI to use Authentik for SSO.
- [ ] **WordPress:**
  - [ ] Configure the OIDC client plugin in each WordPress instance to connect to Authentik.

### 4. Custom WordPress Plugin for OpenWebUI Integration

- [ ] Develop the custom WordPress plugin as per FR5.
  - [ ] Create the admin UI for initiating the connection.
  - [ ] Implement the logic to generate a WordPress Application Password.
  - [ ] Implement the API call to the (assumed) OpenWebUI Admin API to create/link a user and store the Application Password.
- [ ] Add the plugin to the custom WordPress Docker image.

### 5. Ingress Configuration

- [ ] Create an Ingress resource for Authentik in its Helm chart or in the `terraform/platform/main.tf` file.
- [ ] Ensure the Ingress resources for OpenWebUI and WordPress are correctly configured for IP-based access.
