# Project Checklist (Aligned with Product Requirements v2.0)

## Phase 1: Infrastructure Provisioning

- [x] **Terraform Backend**
  - [x] Configure Terraform state backend using IONOS Object Storage (S3-compatible).

- [x] **Kubernetes Cluster & Node Pools**
  - [x] Provision IONOS Managed Kubernetes (MKS) cluster in `de/txl` region.
  - [x] Create at least one node pool with minimal viable instance size.

- [x] **Managed Databases**
  - [x] Provision one IONOS Managed MariaDB cluster *per WordPress tenant* (multi-tenancy).
  - [x] Provision one IONOS Managed PostgreSQL cluster for Authentik.

- [x] **Terraform Outputs**
  - [x] Output Kubeconfig for the MKS cluster.
  - [x] Output connection details (host, port, username, db name) for each MariaDB and the PostgreSQL instance (never output real passwords in plaintext).

- [x] **Secrets Management**
  - [x] Store all sensitive values (IONOS token, DB credentials, API keys) as encrypted secrets in GitHub Actions.
  - [x] Ensure no sensitive values are hardcoded or output in plaintext.

---

## Phase 2: Kubernetes Application Deployment

- [ ] **Namespaces**
  - [ ] Create `admin-apps` namespace for Authentik and OpenWebUI.
  - [ ] Create a dedicated namespace for each WordPress tenant (e.g., `wordpress-tenant-<name>`).

- [ ] **Application Manifests**
  - [ ] Define Deployments, Services, PVCs, ConfigMaps, and Secrets for:
    - [ ] **Authentik:** Uses PostgreSQL, deploys Redis (with PVC), OIDC provider configuration.
    - [ ] **WordPress (per tenant):** Uses its own MariaDB, custom image with required plugins, PVC for `/var/www/html`.
    - [ ] **OpenWebUI:** Configured for Authentik SSO, IONOS LLM endpoint, and MCP communication with all WordPress tenants.

- [ ] **Ingress & Networking**
  - [ ] Configure IP-based Ingress for external access to all UIs (no custom domains/TLS).
  - [ ] Use internal K8s DNS for service-to-service communication (e.g., OpenWebUI to WordPress MCP).

---

## Phase 3: WordPress-OpenWebUI Integration

- [ ] **Custom WordPress Plugin**
  - [ ] Provide a settings page for generating WordPress Application Passwords for MCP.
  - [ ] Interact with OpenWebUI Admin API to create/link user accounts and store passwords.
  - [ ] Add a "Chat" or similar link in WordPress for OpenWebUI access.
  - [ ] Provide clear feedback on setup success/failure.

- [ ] **Plugin Dependencies**
  - [ ] Ensure each WordPress instance includes:
    - [ ] `wordpress-mcp` plugin (v0.2.2).
    - [ ] Open-source OIDC client plugin (e.g., daggerhart's OpenID Connect Generic Client).
    - [ ] The custom integration plugin above.

---

## Phase 4: CI/CD & Secrets Automation

- [ ] **GitHub Actions Workflows**
  - [ ] Authenticate Terraform with IONOS Cloud and Object Storage using secrets.
  - [ ] Deploy infrastructure and store outputs securely.
  - [ ] Use Terraform outputs to create Kubernetes Secrets for application consumption.

- [ ] **Kubernetes Secrets**
  - [ ] Store all sensitive values (DB credentials, API keys, Authentik tokens) in K8s Secrets.
  - [ ] Reference these secrets in application manifests for DB connections, API keys, and OIDC credentials.

---

## Phase 5: Validation & Success Criteria

- [ ] **SSO & User Flows**
  - [ ] Test Authentik as OIDC provider for WordPress and OpenWebUI.
  - [ ] Validate SSO login and redirect flows for all apps.

- [ ] **MCP & LLM Integration**
  - [ ] Ensure OpenWebUI can connect to the IONOS OpenAI-compatible LLM endpoint.
  - [ ] Ensure OpenWebUI can communicate with each WordPress tenant via MCP and send draft blog posts.

- [ ] **Multi-Tenancy**
  - [ ] Confirm each WordPress tenant is isolated (separate namespace, DB, plugins).
  - [ ] Confirm OpenWebUI and Authentik are single instances serving all tenants.

- [ ] **Secrets & Security**
  - [ ] Ensure all sensitive credentials are managed via GitHub Actions and Kubernetes Secrets.
  - [ ] No sensitive values are exposed in logs, outputs, or manifests.

- [ ] **Final Review**
  - [ ] All infrastructure and applications are deployed and integrated as described.
  - [ ] Document findings and lessons learned for future development.
