# GitHub Copilot Custom Instructions: IONOS MKS PoC (Managed DBs, OpenWebUI, Authentik with MCP) - PRD Aligned

## 1. Overall Project Goal & Context (PRD Ref: Sections 1, 2)

We are building a Proof of Concept (PoC) on IONOS Managed Kubernetes (MKS) in region `de/txl`. The project uses Terraform to provision the MKS cluster, an IONOS Managed MariaDB cluster (for WordPress), and an IONOS Managed PostgreSQL cluster (for Authentik). The PoC aims to deploy, integrate, and expose OpenWebUI, WordPress, and Authentik, focusing on SSO and a ModelContextProtocol (MCP) integration between OpenWebUI and WordPress. OpenWebUI will leverage an **IONOS-provided OpenAI-compatible LLM endpoint**. Terraform state will be stored in **IONOS Object Storage (S3-compatible)**. External access will be via **IP-based Ingress (no custom domains/TLS)**.

## 2. Key Technologies & Conventions (PRD Ref: Sections 5, 7)

- **Cloud Provider:** IONOS Cloud (`de/txl` region).
  - Authentication: Assume IONOS provider uses environment variables (`IONOS_TOKEN` or `IONOS_USERNAME`/`IONOS_PASSWORD`).
- **IaC Tool:** Terraform.
  - **Provider:** `ionos-cloud/ionoscloud`.
  - **Backend:** S3-compatible, configured for IONOS Object Storage.
  - **Key Resources:**
    - `ionoscloud_k8s_cluster`
    - `ionoscloud_k8s_node_pool` (minimal viable sizes)
    - `ionoscloud_dbaas_mariadb_cluster` (minimal tier, for WordPress)
    - `ionoscloud_dbaas_postgres_cluster` (minimal tier, for Authentik)
  - **Outputs:** Kubeconfig, DB connection details (host, port, user, password, db_name).
- **Application Deployment on MKS:** Kubernetes manifests (YAML).
  - **Namespaces:**
    - `admin-apps`: For Authentik and OpenWebUI.
    - `wordpress-tenants`: For WordPress.
  - **Workloads:** `Deployments`. Authentik deploys its server/worker and an internal Redis (with PVC).
  - **Networking:** `Services` (`ClusterIP`, `LoadBalancer` for Ingress). `Ingress` for IP-based external access.
    - Internal K8s DNS for service-to-service: e.g., `wordpress-mcp-service.wordpress-tenants.svc.cluster.local`.
  - **Storage:** `PersistentVolumeClaims` (PVCs) for WordPress `/var/www/html`, OpenWebUI config, Authentik media/certs, Authentik Redis.
  - **Configuration:** `ConfigMaps`.
  - **Secrets:** Kubernetes `Secrets` managed via **GitHub Actions** for DB connections, API keys, Authentik tokens.
- **Container Images:**
  - **WordPress:** Custom image (e.g., based on `wordpress-fpm-alpine` + Nginx, or Apache-based) including:
    - `wordpress-mcp` plugin (v0.2.2 from `https://github.com/Automattic/wordpress-mcp/releases/download/v0.2.2/wordpress-mcp.zip`).
    - OIDC SSO client plugin (e.g., "OpenID Connect Generic Client by daggerhart").
    - **Custom WordPress plugin for OpenWebUI integration (see Section 5 of this file).**
  - **OpenWebUI:** Standard image. Configured for:
    - IONOS OpenAI-compatible LLM endpoint (API key & base URL via K8s Secret).
    - Authentik SSO.
    - MCP communication with WordPress.
  - **Authentik:** Official images.
- **ModelContextProtocol (MCP):** Via `Automattic/wordpress-mcp` plugin on WordPress. OpenWebUI acts as a client.
- **SSO:** Authentik as OIDC provider for WordPress and OpenWebUI.

## 3. IONOS MKS Cluster & Managed Databases Setup (Terraform Focus - PRD Ref: FR1)

- Target minimal viable sizes for MKS node pools and DBaaS instances in `de/txl`.
- Configure Terraform `backend "s3"` for IONOS Object Storage (expect credentials via environment variables in GitHub Actions).
- Ensure Terraform outputs Kubeconfig and full connection details for MariaDB and PostgreSQL (to be used in K8s Secrets).

## 4. Application Deployment on Kubernetes (Manifest Focus - PRD Ref: FR2, FR3, FR4)

### 4.1. General Principles:

- Use defined namespaces: `admin-apps` and `wordpress-tenants`.
- Consistent labeling, resource requests/limits, `livenessProbe`/`readinessProbe`.

### 4.2. Authentik (`admin-apps` namespace - PRD Ref: FR2):

- Connects to IONOS Managed PostgreSQL (credentials from K8s Secret).
- Deploys its own Redis with a PVC.
- External access via IP-based Ingress.
- Configure OIDC provider and client applications for WordPress & OpenWebUI.

### 4.3. WordPress (`wordpress-tenants` namespace - PRD Ref: FR3):

- Connects to IONOS Managed MariaDB (credentials from K8s Secret).
- PVC for `/var/www/html`.
- Custom image includes `wordpress-mcp` (v0.2.2), OIDC client, and **custom OpenWebUI integration plugin**.
- External access via IP-based Ingress.
- Configure OIDC client for Authentik.

### 4.4. OpenWebUI (`admin-apps` namespace - PRD Ref: FR4):

- PVC for configuration data (not models).
- Configure for IONOS OpenAI-compatible LLM endpoint (API key & base URL from K8s Secret).
- External access via IP-based Ingress.
- Configure OIDC client for Authentik.
- Configure with WordPress MCP endpoint URL (e.g., `http://wordpress-mcp-service.wordpress-tenants.svc.cluster.local/wp-json/mcp/v1`) and the WordPress Application Password obtained via the custom WP plugin flow (see Section 5).

## 5. WordPress-OpenWebUI Integration (Custom WordPress Plugin - PRD Ref: FR5)

This is a **NEW DEVELOPMENT PIECE** for the PoC.

- **Goal:** Create a custom WordPress plugin to facilitate the setup of communication from OpenWebUI back to WordPress via MCP.
- **Functionality:**
  1.  Provides a UI in WP Admin (e.g., settings page with a button).
  2.  Guides WP Admin to generate a WordPress Application Password scoped for OpenWebUI's MCP access.
  3.  _(Assumption A4 from PRD)_ The WP plugin, using an OpenWebUI Admin API Token (itself a K8s Secret, configured in WP), calls an OpenWebUI Admin API to:
      - Create a user account in OpenWebUI (or link existing).
      - Securely store the generated WordPress Application Password within that OpenWebUI user's profile/settings.
  4.  Provides feedback on the setup process.
  5.  A "Chat" link in WordPress directs users to their OpenWebUI.
- **Copilot Guidance Needed For:** PHP code for the WP plugin, interacting with WP Application Passwords, making external API calls (to OpenWebUI), and handling settings. Understanding OpenWebUI's API for user creation and storing external tokens is critical (_PRD OQ3, Assumption A4_).

## 6. Inter-Service Communication & SSO Flow (PRD Ref: FR6)

- **MCP:** OpenWebUI (client) calls WordPress MCP endpoint (e.g. `wordpress-mcp-service.wordpress-tenants.svc.cluster.local`). Authentication via WordPress Application Password.
- **Database Connections:** Pods connect to external IONOS DBaaS endpoints using credentials from K8s Secrets.
- **SSO:** Authentik is OIDC provider. WordPress and OpenWebUI are OIDC clients. Redirect URIs and client credentials (stored in K8s Secrets for apps) are key.

## 7. Secrets Management & CI/CD (PRD Ref: FR7)

- **Primary Tool:** GitHub Actions.
- Store sensitive values (IONOS Terraform token, OpenWebUI Admin API token for WP plugin, etc.) as GitHub Actions encrypted secrets.
- Workflows will:
  - Use secrets to auth Terraform with IONOS Cloud and IONOS Object Storage.
  - Take Terraform outputs (DB connection details) and use `kubectl` (or Terraform Kubernetes provider) to create/update K8s Secrets in the appropriate namespaces.

## 8. General Guidance for Copilot Chat

- Prioritize IONOS MKS (`de/txl`), IONOS Managed DBaaS, and IONOS Object Storage.
- Focus on **minimal viable configurations** for PoC.
- **Terraform:** Help with S3 backend, `ionoscloud_*` resources, outputting secrets.
- **Kubernetes:** Structure YAML for Deployments, Services, IP-based Ingress, PVCs, ConfigMaps, Secrets, respecting `admin-apps` and `wordpress-tenants` namespaces.
- **WordPress Custom Plugin (FR5):** This is a key area. Assist with PHP, WP hooks, Application Passwords API, and calling external (OpenWebUI) APIs. Acknowledge dependency on OpenWebUI's API capabilities (PRD Assumption A4).
- **OpenWebUI Config:** Focus on OIDC setup and configuring the **external IONOS OpenAI-compatible LLM endpoint** (API key/URL from Secrets).
- **Secrets:** Emphasize creation of K8s Secrets from GitHub Actions workflow, using Terraform outputs.
- **Networking:** Remind about internal K8s DNS (e.g., `servicename.namespace.svc.cluster.local`) and IP-based external Ingress.
- **SSO:** Guide on OIDC flow, Authentik client app config, and app-side OIDC plugin setup.
- Refer to PRD sections (e.g., "per FR4.6", "addressing OQ3") for detailed context if needed.

## 9. Additional Notes

- Always fix the issue directly instead of asking for permission.
