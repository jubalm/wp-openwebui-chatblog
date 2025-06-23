# Project Checklist

## Phase 1: Infrastructure Setup

- [ ] **Terraform Configuration:**

  - [ ] Set up the Terraform backend using IONOS Object Storage (S3-compatible).
  - [ ] Configure Terraform resources for:
    - [ ] IONOS Managed Kubernetes (MKS) cluster in `de/txl`.
    - [ ] IONOS Managed MariaDB cluster for WordPress.
    - [ ] IONOS Managed PostgreSQL cluster for Authentik.
  - [ ] Output Kubeconfig and database connection details.

- [ ] **GitHub Actions Integration:**
  - [ ] Create workflows to:
    - [ ] Authenticate Terraform with IONOS Cloud and Object Storage using secrets.
    - [ ] Deploy infrastructure and store outputs.
    - [ ] Use Terraform outputs to create Kubernetes Secrets.

---

## Phase 2: Kubernetes Deployment

- [ ] **Namespaces:**

  - [ ] Create `admin-apps` for Authentik and OpenWebUI.
  - [ ] Create `wordpress-tenants` for WordPress.

- [ ] **Manifests:**

  - [ ] Define Deployments, Services, PVCs, ConfigMaps, and Secrets for:
    - [ ] **Authentik:** PostgreSQL connection, Redis setup, OIDC provider configuration.
    - [ ] **WordPress:** MariaDB connection, custom image with plugins, PVC for `/var/www/html`.
    - [ ] **OpenWebUI:** Configuration for IONOS OpenAI-compatible LLM endpoint, OIDC client setup, MCP communication.

- [ ] **Networking:**
  - [ ] Configure IP-based Ingress for external access.
  - [ ] Use internal K8s DNS for service-to-service communication.

---

## Phase 3: WordPress Plugin Development

- [ ] **Custom Plugin:**

  - [ ] Develop a WordPress plugin to:
    - [ ] Provide a settings page for generating WordPress Application Passwords.
    - [ ] Interact with OpenWebUI Admin API to create/link user accounts and store passwords.
    - [ ] Add a "Chat" link in WordPress for OpenWebUI access.

- [ ] **Integration Testing:**
  - [ ] Test MCP communication between OpenWebUI and WordPress.
  - [ ] Validate SSO flow using Authentik.

---

## Phase 4: Secrets Management

- [ ] **Kubernetes Secrets:**

  - [ ] Store sensitive values (DB credentials, API keys) in K8s Secrets.
  - [ ] Ensure GitHub Actions workflows manage Secrets securely.

- [ ] **Application Configuration:**
  - [ ] Use Secrets in application manifests for database connections, API keys, and OIDC credentials.

---

## Phase 5: Final Validation

- [ ] **SSO Flow:**

  - [ ] Test Authentik as OIDC provider for WordPress and OpenWebUI.
  - [ ] Validate redirect URIs and client credentials.

- [ ] **Inter-Service Communication:**

  - [ ] Ensure OpenWebUI can call WordPress MCP endpoint securely.
  - [ ] Verify database connections and application functionality.

- [ ] **PoC Review:**
  - [ ] Confirm all components are deployed and integrated successfully.
  - [ ] Document findings and prepare for next steps.
