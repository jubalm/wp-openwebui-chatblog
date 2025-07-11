---
Version: 3.0
Date: Template
Author: Jubal Mabaquiao
Status: Configuration templates ready for implementation
---

## Product Requirements Document: IONOS MKS PoC (Managed DBs, OpenWebUI, Authentik with MCP)

### 1. Introduction & Overview

This document outlines the requirements for a Proof of Concept (PoC) project. The primary goal is to demonstrate the deployment, integration, and operation of a suite of interconnected applications (OpenWebUI, multiple WordPress instances, Authentik) on IONOS Managed Kubernetes (MKS). The PoC will leverage IONOS Managed Database services (MariaDB for each WordPress tenant, PostgreSQL for Authentik) and will utilize Terraform for infrastructure provisioning. A key integration point is a custom "ModelContextProtocol" (MCP) enabling communication between OpenWebUI and each WordPress instance. This PoC aims to validate the chosen technology stack and integration patterns on the IONOS Cloud platform, with a core focus on multi-tenancy: a single OpenWebUI and Authentik instance, and multiple isolated WordPress instances (one per tenant).

### Configuration Template

**Platform Configuration Framework - Phases 1 & 2**

- **Cluster ID**: `<cluster-id>`
- **LoadBalancer IP**: `<loadbalancer-ip>`
- **Region**: `de/txl`

**Service Endpoint Configuration**:
- **WordPress**: `http://wordpress-tenant1.local` → `<loadbalancer-ip>` (Multi-tenant CMS)
- **OpenWebUI**: `http://openwebui.local` → `<loadbalancer-ip>` (OAuth2 integration)
- **Authentik**: `http://authentik.local` → `<loadbalancer-ip>` (SSO authentication)

### 2. Goals & Objectives

- **G1:** Successfully provision an IONOS MKS cluster and associated IONOS Managed Database instances (MariaDB, PostgreSQL) using Terraform.
- **G2:** Deploy OpenWebUI, multiple WordPress instances, and Authentik containerized applications onto the MKS cluster.
- **G3:** Integrate Authentik as an SSO provider for both OpenWebUI and each WordPress instance.
- **G4:** Enable OpenWebUI to interact with an IONOS-provided OpenAI-compatible LLM endpoint.
- **G5:** Enable OpenWebUI to communicate with each WordPress instance via the ModelContextProtocol (MCP) to draft blog posts.
- **G6:** Implement a secure and automated way to manage infrastructure and application secrets, leveraging GitHub Actions.
- **G7:** Establish foundational understanding and best practices for deploying such a stack on IONOS Cloud for potential future development.

### 3. Target Audience/Users (for this PoC)

- **PoC Implementer(s):** Developers/Engineers responsible for building, deploying, and validating the PoC.
- **Technical Stakeholders:** Individuals evaluating the feasibility and architecture of using IONOS MKS and related services.
- **PoC Testers:** Individuals who will execute the defined user flows to validate success criteria.

### 4. Scope

#### 4.1. In Scope:

- Terraform scripts for MKS cluster, node pools, IONOS Managed MariaDB, and IONOS Managed PostgreSQL.
- Terraform backend configured for IONOS Object Storage.
- Deployment of Authentik on MKS, using IONOS Managed PostgreSQL.
- Deployment of multiple WordPress instances on MKS, each using its own IONOS Managed MariaDB instance, including:
  - Official Automattic `wordpress-mcp` plugin (v0.2.2).
  - An open-source OIDC SSO client plugin (e.g., "OpenID Connect Generic Client by daggerhart").
  - A custom WordPress plugin to facilitate OpenWebUI integration setup (details in Functional Requirements).
- Deployment of a single OpenWebUI on MKS, configured for:
  - Authentik SSO.
  - Connection to an IONOS-provided OpenAI-compatible LLM endpoint.
  - Connection to all WordPress instances via MCP.
- Basic Kubernetes resources: Namespaces (`admin-apps`, and one namespace per WordPress tenant, e.g., `wordpress-tenant-<name>`), Deployments, Services, PersistentVolumeClaims (for application data like WordPress `/var/www/html`, Authentik Redis, OWUI config), ConfigMaps, Secrets.
- Ingress configuration for IP-based access (no custom domains or TLS) to externally exposed application UIs.
- Secrets management strategy using GitHub Actions and Kubernetes Secrets for sensitive data (database credentials, API keys, Authentik bootstrap tokens).
- Demonstration of core user flows (SSO login, content generation via OWUI to any tenant's WordPress).

#### 4.2. Out of Scope:

- Production-grade hardening, security scanning, or performance optimization.
- Advanced monitoring, logging, and alerting beyond Kubernetes defaults.
- Custom domain name configuration and TLS certificate management for Ingress.
- High availability (HA) configurations beyond what IONOS MKS/DBaaS provide by default for selected minimal tiers.
- Detailed UI/UX customization of applications beyond functional necessity for the PoC.
- Data migration strategies.
- Load testing or performance benchmarking.

### 5. Core Components & Technologies

- **Cloud Platform:** IONOS Cloud
  - IONOS Managed Kubernetes (MKS) - Region: `de/txl`
  - IONOS Managed MariaDB (for WordPress) - Region: `de/txl`
  - IONOS Managed PostgreSQL (for Authentik) - Region: `de/txl`
  - IONOS Object Storage (S3-compatible, for Terraform state)
  - IONOS OpenAI-compatible LLM Endpoint
- **Infrastructure as Code:** Terraform
  - Provider: `ionos-cloud/ionoscloud`
- **Container Orchestration:** Kubernetes (via MKS)
- **Applications:**
  - **Authentik:** SSO Provider (using official container images). Will deploy its own Redis instance within Kubernetes.
  - **WordPress:** Blog Platform (custom Docker image based on `wordpress-fpm-alpine` or similar, including `wordpress-mcp` and OIDC plugins). Potentially with an Nginx reverse proxy in the same pod.
  - **OpenWebUI:** Web UI for LLMs (official container image).
- **CI/CD & Secrets:** GitHub Actions
- **Key Protocols/Integrations:**
  - OIDC (for SSO)
  - ModelContextProtocol (MCP - custom, via `Automattic/wordpress-mcp` plugin)
  - OpenAI API (for LLM interaction)

### 6. Functional Requirements

- **FR1: Infrastructure Provisioning (Terraform)**

  - **FR1.1:** As a PoC Implementer, I can run Terraform scripts to create an MKS cluster in `de/txl` with at least one node pool using minimal viable instance sizes.
  - **FR1.2:** As a PoC Implementer, I can run Terraform scripts to provision an IONOS Managed MariaDB cluster (minimal tier) for each WordPress tenant.
  - **FR1.3:** As a PoC Implementer, I can run Terraform scripts to provision an IONOS Managed PostgreSQL cluster (minimal tier) for Authentik.
  - **FR1.4:** Terraform state shall be stored securely in IONOS Object Storage.
  - **FR1.5:** Terraform outputs must include Kubeconfig for MKS, and connection details (host, port, user, password, db name) for each MariaDB and the PostgreSQL instance.

- **FR2: Authentik Deployment & Configuration**

  - **FR2.1:** Authentik shall be deployed on MKS within the `admin-apps` namespace.
  - **FR2.2:** Authentik shall use the IONOS Managed PostgreSQL instance as its database. Connection details will be supplied via Kubernetes Secrets.
  - **FR2.3:** Authentik shall deploy its own Redis instance within its Kubernetes deployment, using a PVC for persistence.
  - **FR2.4:** Authentik's UI shall be accessible externally via an IP-based Ingress rule.
  - **FR2.5:** Authentik shall be configured as an OIDC provider.
  - **FR2.6:** OIDC client applications for all WordPress tenants and OpenWebUI shall be configured within Authentik.

- **FR3: WordPress Deployment & Configuration**

  - **FR3.1:** Each WordPress tenant shall be deployed on MKS within its own namespace (e.g., `wordpress-tenant-<name>`).
  - **FR3.2:** Each WordPress instance shall use its own IONOS Managed MariaDB instance as its database. Connection details will be supplied via Kubernetes Secrets.
  - **FR3.3:** WordPress data (`/var/www/html`) shall be persisted using a PVC.
  - **FR3.4:** Each WordPress deployment shall include:
    - The `wordpress-mcp` plugin (v0.2.2).
    - An open-source OIDC client plugin.
    - A custom plugin for OpenWebUI integration setup (see FR5).
  - **FR3.5:** Each WordPress Admin UI and blog frontend shall be accessible externally via an IP-based Ingress rule.
  - **FR3.6:** Each WordPress instance shall be configured as an OIDC client to Authentik for user login.

- **FR4: OpenWebUI Deployment & Configuration**

  - **FR4.1:** OpenWebUI shall be deployed on MKS within the `admin-apps` namespace.
  - **FR4.2:** OpenWebUI configuration data shall be persisted using a PVC.
  - **FR4.3:** OpenWebUI shall be configured to use the IONOS-provided OpenAI-compatible LLM endpoint. The endpoint URL and API key will be supplied via Kubernetes Secrets.
  - **FR4.4:** OpenWebUI's UI shall be accessible externally via an IP-based Ingress rule.
  - **FR4.5:** OpenWebUI shall be configured as an OIDC client to Authentik for user login.
  - **FR4.6:** OpenWebUI shall be configured to communicate with the MCP endpoint of any tenant's WordPress instance (e.g., `http://wordpress-mcp-service.wordpress-tenant-<name>.svc.cluster.local/wp-json/mcp/v1`).

- **FR5: WordPress-OpenWebUI Integration (Custom WordPress Plugin)**

  - **FR5.1:** The custom WordPress plugin shall provide a UI (e.g., a settings page with a button) within the WP Admin area for an administrator to initiate a connection setup with OpenWebUI.
  - **FR5.2:** _Assumption:_ Upon initiation, the plugin will guide the WP admin to generate a WordPress Application Password scoped for OpenWebUI's MCP access.
  - **FR5.3:** _Assumption:_ The plugin (requiring an OpenWebUI Admin API token) will then call an OpenWebUI API to create a new user account in OpenWebUI (or link an existing one).
  - **FR5.4:** _Assumption:_ The WordPress Application Password (from FR5.2) will be securely passed to and stored within the corresponding user's profile/settings in OpenWebUI, enabling OpenWebUI to authenticate MCP requests back to WordPress.
  - **FR5.5:** The WordPress plugin UI shall provide clear feedback on the success or failure of this setup process.
  - **FR5.6:** A "Chat" or similar link/menu item shall be available in WordPress (e.g., for logged-in users) that directs the user to their corresponding OpenWebUI interface.

- **FR6: User Flows & End-to-End Functionality**

  - **FR6.1:** A user can navigate to the WordPress login page and be redirected to Authentik for authentication. Upon successful login, they are returned to WordPress as a logged-in user.
  - **FR6.2:** A user can navigate to the OpenWebUI login page and be redirected to Authentik for authentication. Upon successful login, they are returned to OpenWebUI as a logged-in user.
  - **FR6.3 (MCP Flow):** A user logged into OpenWebUI can use its interface (leveraging the IONOS LLM) to generate content, and then use an OpenWebUI feature to send this content as a draft blog post to their connected WordPress instance via MCP. The draft should appear in WordPress.

- **FR7: Secrets Management (GitHub Actions)**
  - **FR7.1:** Sensitive values (IONOS token, DBaaS bootstrap passwords if manually set, OpenWebUI Admin API token for WP plugin) shall be stored as encrypted secrets in GitHub Actions.
  - **FR7.2:** GitHub Actions workflows shall use these secrets to:
    - Authenticate Terraform for infrastructure provisioning.
    - Populate Kubernetes Secrets with database connection details (sourced from Terraform outputs) and other application API keys.

### 7. Technical Requirements

- **TR1: Infrastructure:** All infrastructure defined in Terraform, deployed in IONOS `de/txl` region. Use minimal viable resource sizes.
- **TR2: Containerization:** All applications deployed as Docker containers on MKS. WordPress image to be custom-built to include necessary plugins.
- **TR3: Networking:**
  - Internal communication between pods (e.g., OWUI to WordPress MCP) will use Kubernetes internal DNS service names.
  - External access to UIs via IP-based Kubernetes Ingress.
- **TR4: State Persistence:** Terraform state in IONOS S3. Application data via Kubernetes PVCs.
- **TR5: Namespacing:** Use `admin-apps` for Authentik & OpenWebUI, and `wordpress-tenants` for WordPress.

### 8. Assumptions

- **A1:** IONOS MKS, Managed DBaaS, and Object Storage services in `de/txl` meet the basic functional needs for this PoC.
- **A2:** Minimal viable instance/tier sizes for MKS and DBaaS are sufficient for PoC functionality (performance is not a primary goal).
- **A3:** The IONOS-provided OpenAI-compatible LLM endpoint is available and functions as expected with standard OpenAI API key and base URL configuration.
- **A4 (Critical for FR5):** OpenWebUI provides an administrative API that allows:
  - Programmatic creation of user accounts.
  - Programmatic association of an external API token (the WordPress Application Password) with a user account for outbound API calls from OpenWebUI.
  - _If A4 is false, FR5 functionality will need significant re-evaluation and simplification._
- **A5:** The chosen open-source OIDC client plugin for WordPress integrates correctly with Authentik.
- **A6:** The Automattic `wordpress-mcp` plugin (v0.2.2) is suitable for the MCP communication needs.
- **A7:** IP-based access is sufficient for PoC validation; no DNS names or TLS setups are required for external access.

### 9. Open Questions / Research Items

- **OQ1:** Confirm the exact smallest instance types/tiers for `ionoscloud_k8s_node_pool`, `ionoscloud_dbaas_mariadb_cluster`, and `ionoscloud_dbaas_postgres_cluster` in `de/txl`.
- **OQ2:** Verify the specific environment variable names OpenWebUI expects for `OPENAI_API_BASE_URL` and `OPENAI_API_KEY`.
- **OQ3 (Critical for FR5):** Investigate and confirm OpenWebUI's Admin API capabilities regarding user creation and storage of third-party API tokens for users (ref A4).
- **OQ4:** Select and confirm the specific open-source OIDC SSO client plugin for WordPress and its configuration requirements. (Candidate: OpenID Connect Generic Client by daggerhart).
- **OQ5:** Determine the best strategy for the WordPress Docker image (official Apache-based vs. FPM + separate Nginx pod container) for simplicity vs. flexibility within the PoC.
- **OQ6:** Define the exact mechanism/API endpoint by which OpenWebUI will "send a draft to WordPress" via MCP. (Assumed to be part of OpenWebUI's native features when an MCP integration is configured).

### 10. Success Criteria / Definition of Done

The PoC will be considered successful when:

- **SC1:** Infrastructure components (MKS, MariaDB for each tenant, PostgreSQL) configuration ready for provisioning via Terraform, with state in IONOS Object Storage.
  - MKS Cluster: `<cluster-id>`
  - PostgreSQL: `pg-ng6akjkmbb4rn9e5.postgresql.de-txl.ionos.com`
  - MariaDB: `ma-d8nn61870q23eimk.mariadb.de-txl.ionos.com`
- **SC2:** Authentik, WordPress tenant instances, and OpenWebUI configuration ready for deployment on MKS cluster in designated namespaces.
- **SC3:** SSO authentication configuration for WordPress tenants using Authentik credentials.
- **SC4:** SSO authentication configuration for OpenWebUI using Authentik credentials.
  - OAuth2 Provider: "Authentik SSO" configured and operational
- **SC5:** OpenWebUI configuration for connecting to IONOS-provided OpenAI-compatible LLM endpoint.
- **SC6:** Custom WordPress plugin configuration for API-driven setup linking OpenWebUI user context to WordPress tenants for MCP.
  - WordPress OAuth2 Pipeline service deployed with content automation
- **SC7:** OpenWebUI content generation workflow configuration for sending drafts to linked WordPress tenant instances via MCP integration.
  - Content automation service with intelligent processing operational
- **SC8:** Credential management configuration through GitHub Actions secrets and Kubernetes Secrets, avoiding hardcoded values.
  - All secrets managed via `authentik-env-secrets`, `openwebui-env-secrets`, `wordpress-oauth-env-secrets`

### 11. Implementation Timeline

- **Phase 1 (SSO Foundation)**: Configuration templates ready
  - PostgreSQL deployment configuration, Authentik setup, OAuth2 providers configuration
- **Phase 2 (Content Integration)**: Architecture design complete
  - WordPress OAuth2 pipeline configuration, content automation service, OpenWebUI integration
- **Phase 3 (Deployment Automation)**: Implementation needed
  - GitHub Actions workflows, automated testing, monitoring
