# GitHub Copilot Custom Instructions: IONOS MKS PoC (Managed DBs, OpenWebUI, Authentik with MCP)

## 1. Overall Project Goal & Context

We are building a Proof of Concept (PoC) on **IONOS Managed Kubernetes (MKS)** using **Terraform** to provision the MKS cluster, an **IONOS Managed MariaDB cluster (for WordPress)**, and an **IONOS Managed PostgreSQL cluster (for Authentik)**.
The PoC aims to deploy, integrate, and expose the following containerized applications on MKS:

1.  **OpenWebUI (OWUI):**
    - Single instance deployed on MKS.
    - Intended for multi-tenancy (one admin account, multiple user accounts).
    - Will include or develop **tools/integrations to communicate with a WordPress "MCP Server"** (ModelContextProtocol - a custom API/protocol).
    - Will be integrated with Authentik for SSO.
2.  **WordPress:**
    - Single-tenant blog platform deployed on MKS.
    - Will connect to an **IONOS Managed MariaDB cluster** for its database.
    - Will have a **plugin acting as an "MCP Server"** for OpenWebUI to connect to.
    - Will likely require an **SSO plugin** (e.g., OAuth/OIDC) to integrate with Authentik.
3.  **Authentik:**
    - SSO provider deployed on MKS.
    - Will connect to an **IONOS Managed PostgreSQL cluster** for its primary database.
    - Will deploy its own Redis instance within Kubernetes (unless a managed Redis is also specified later).
    - Will provide authentication for user accounts across both WordPress and OpenWebUI tenants.

The primary objective is to demonstrate deploying these interconnected applications on IONOS MKS, utilizing IONOS DBaaS for both WordPress and Authentik's PostgreSQL, and handling state, configuration, and exposure.

## 2. Key Technologies & Conventions

- **Cloud Provider:** IONOS Cloud. Assume authentication is handled via environment variables (`IONOS_TOKEN` or `IONOS_USERNAME`/`IONOS_PASSWORD`) for the IONOS Terraform provider.
- **IaC Tool:** Terraform.
  - **Provider:** `ionos-cloud/ionoscloud`.
  - **Key Terraform Resources:**
    - `ionoscloud_k8s_cluster`: For provisioning the MKS cluster.
    - `ionoscloud_k8s_node_pool`: For defining node pools.
    - `ionoscloud_dbaas_mariadb_cluster` (or similar): For WordPress.
    - `ionoscloud_dbaas_postgres_cluster` (or similar): For Authentik's PostgreSQL.
    - (Potentially `ionoscloud_ipblock` if a static IP is needed for Ingress, though MKS often provisions LoadBalancer IPs).
  - **File Structure (Terraform):**
    - `mks.tf` (MKS cluster, node pools)
    - `database.tf` (managed MariaDB and PostgreSQL clusters)
    - `variables.tf` (cluster versions, node sizes, DB parameters, image names, secrets etc.)
    - `outputs.tf` (kubeconfig, cluster endpoint, MariaDB & PostgreSQL connection details)
- **Application Deployment on MKS:** Kubernetes manifests (YAML).
  - **Workloads:** `Deployments` for applications. Authentik will deploy its server/worker and Redis components.
  - **Networking:** `Services` (ClusterIP, NodePort, LoadBalancer), `Ingress` (for external access, likely using the IONOS CCM to provision a Load Balancer).
  - **Storage (Application Data):** `PersistentVolumeClaims` (PVCs) for WordPress `/var/www/html`, OpenWebUI data, Authentik media/certs and its internal Redis data. Database storage for WordPress & Authentik's PostgreSQL is handled by IONOS DBaaS.
  - **Configuration:** `ConfigMaps` for non-sensitive configuration.
  - **Secrets:** Kubernetes `Secrets` for database connections (WordPress to MariaDB, Authentik to PostgreSQL), API keys, Authentik bootstrap tokens, OIDC client secrets.
  - **Namespaces:** Consider using separate namespaces for each application or a common namespace for the PoC (e.g., `poc-apps`).
- **Container Images:**
  - WordPress: Custom image (`var.custom_wordpress_image`) if the MCP server plugin is pre-baked; otherwise, a standard image with the plugin installed via an init container or post-deployment.
  - OpenWebUI: Standard image (`var.openwebui_image`), with MCP client tools potentially added or configured.
  - Authentik: Official images for server, worker, PostgreSQL (if self-hosted, but we are using DBaaS), Redis.
- **ModelContextProtocol (MCP):** This is a custom protocol/API. Assume WordPress exposes an MCP endpoint, and OpenWebUI consumes it. This will mainly influence application-level configuration, potentially service discovery within Kubernetes, and Ingress/Service definitions for WordPress.

## 3. IONOS MKS Cluster & Managed Databases Setup (Terraform Focus)

- **`ionoscloud_k8s_cluster`**: Define the MKS cluster, specifying Kubernetes version, name, and any specific features.
- **`ionoscloud_k8s_node_pool`**: Define at least one node pool with appropriate instance sizes for the workloads.
- **`ionoscloud_dbaas_mariadb_cluster`**: Define the managed MariaDB cluster for WordPress, specifying version, size/tier, name, admin username/password (or let IONOS generate and output). Ensure networking allows MKS pods to connect.
- **`ionoscloud_dbaas_postgres_cluster` (or equivalent for PostgreSQL):** Define the managed PostgreSQL cluster for Authentik, specifying version, size/tier, name, admin username/password. Ensure networking allows MKS pods (Authentik) to connect.
- **Kubeconfig & DB Connection Outputs:** Terraform should output the necessary information to obtain the kubeconfig for `kubectl` access, and the connection details for **both managed MariaDB and PostgreSQL instances** (hostname, port, DB name, user, password). These outputs will be used to configure WordPress and Authentik via Kubernetes Secrets.
- **Terraform Kubernetes Provider:** Once the MKS cluster is up, we might use the Terraform Kubernetes provider to deploy initial namespaces or common resources like Secrets (populated from DBaaS outputs).

## 4. Application Deployment on Kubernetes (Manifest Focus)

### 4.1. General Kubernetes Manifest Principles:

- **Labels and Selectors:** Use consistent labeling for all resources related to an application (e.g., `app: wordpress`, `component: web`).
- **Resource Requests and Limits:** Define sensible CPU/memory requests and limits for pods to ensure stable performance and resource allocation.
- **Probes:** Implement `livenessProbe` and `readinessProbe` for Deployments to help Kubernetes manage pod health and readiness for traffic.
- **Service Accounts:** Consider if applications need specific service accounts with RBAC permissions (less likely for this PoC unless interacting directly with Kubernetes API).
- **Security Contexts:** Define security contexts for pods and containers where appropriate (e.g., `runAsNonRoot: true`, read-only root filesystem).

### 4.2. Authentik on MKS (Connecting to Managed PostgreSQL):

- **Deployment Strategy:**
  - `Deployments` for Authentik server and worker components.
  - **No PostgreSQL Deployment in K8s:** Authentik will connect to the IONOS Managed PostgreSQL.
  - **Redis:** Authentik requires Redis. This will be deployed as a `Deployment` with a `PersistentVolumeClaim` for its data within Kubernetes.
- **`PersistentVolumeClaims`:** For Authentik media, certificates, and **Redis data**. No PVC for PostgreSQL data.
- **`Secrets`:**
  - A Kubernetes `Secret` will store connection details for the **IONOS Managed PostgreSQL**. This will include keys like `AUTHENTIK_POSTGRESQL__HOST`, `AUTHENTIK_POSTGRESQL__PORT`, `AUTHENTIK_POSTGRESQL__NAME`, `AUTHENTIK_POSTGRESQL__USER`, `AUTHENTIK_POSTGRESQL__PASSWORD`. These values are sourced from Terraform outputs.
  - Another Kubernetes `Secret` for `AUTHENTIK_SECRET_KEY` and any other sensitive bootstrap values.
  - Inject these secrets as environment variables into Authentik server/worker pods.
- **`ConfigMaps`:** For non-sensitive Authentik configurations or to bootstrap environment variables that point to the secret keys.
- **`Service`:** `ClusterIP` services for internal communication (e.g., Authentik server to its Redis). A `LoadBalancer` or `NodePort` service, exposed via `Ingress`, for external access to Authentik UI (ports 9000/9443).
- **`Ingress`:** To expose Authentik externally with a proper hostname and TLS.

### 4.3. WordPress on MKS (Connecting to Managed MariaDB):

- **`Deployment`:** For the WordPress application pod(s).
- **`PersistentVolumeClaim`:** **Only for `/var/www/html`** (WordPress content, themes, plugins). No PVC for database data itself.
- **`Secrets`:**
  - A Kubernetes `Secret` will store the connection details for the **IONOS Managed MariaDB**. This will include keys like `WORDPRESS_DB_HOST` (or `DB_HOST`), `WORDPRESS_DB_USER`, `WORDPRESS_DB_PASSWORD`, `WORDPRESS_DB_NAME`. These values are sourced from Terraform outputs.
  - Mount these secrets as environment variables into the WordPress pods.
- **`ConfigMaps`:** For WordPress salts or other non-sensitive configurations.
- **MCP Server Plugin:** This plugin needs to be present in the WordPress container. Configuration for it might go into a `ConfigMap`.
- **SSO Plugin:** Configuration for the OIDC/OAuth2 plugin to connect to Authentik (client ID, client secret from Authentik, redirect URIs). Client secrets should be stored in Kubernetes Secrets.
- **`Service`:** `ClusterIP` service for internal access (e.g., for OpenWebUI to reach the MCP endpoint). A `LoadBalancer` or `NodePort` service, exposed via `Ingress`, for external access to the blog.
- **`Ingress`:** To expose WordPress externally. The MCP endpoint might need a specific path on this Ingress or be purely internal via its `ClusterIP` service.

### 4.4. OpenWebUI on MKS:

- **`Deployment`:** For the OpenWebUI application pod(s).
- **`PersistentVolumeClaim`:** For any persistent data OpenWebUI requires (e.g., `/app/backend/data`, user configurations, local models if applicable).
- **`ConfigMaps` / `Secrets`:**
  - For API keys, connection details to the WordPress MCP server (e.g., internal service DNS name of WordPress).
  - For OIDC client secrets for Authentik integration (client ID, client secret from Authentik, redirect URIs). Store client secret in a Kubernetes Secret.
- **MCP Client Tools:** Configuration for these tools, including the address of the WordPress MCP service (e.g., `http://wordpress-service.poc-apps.svc.cluster.local/mcp-endpoint`).
- **`Service`:** `ClusterIP` service for internal access if other components needed to call it. A `LoadBalancer` or `NodePort` service, exposed via `Ingress`, for external access to the OpenWebUI interface.
- **`Ingress`:** To expose OpenWebUI externally.

## 5. Inter-Service Communication & SSO Flow

- **Internal Communication (MCP):** OpenWebUI pods will need to resolve and communicate with the WordPress (MCP server) service within the Kubernetes cluster (e.g., `http://wordpress-service.namespace.svc.cluster.local/mcp-endpoint`).
- **WordPress Database Connection:** WordPress pods will connect to the external IONOS Managed MariaDB endpoint using the credentials provided via Kubernetes Secrets. Ensure MKS network policies/firewalls allow outbound traffic to the DBaaS endpoint if necessary (usually within IONOS private network should be fine).
- **Authentik Database Connection:** Authentik pods will connect to the external IONOS Managed PostgreSQL endpoint using credentials from Kubernetes Secrets. Ensure MKS network policies/firewalls allow this.
- **SSO Integration:**
  - Authentik will be the OIDC provider.
  - WordPress (via an OIDC plugin) will be an OIDC client, redirecting users to Authentik for login.
  - OpenWebUI will also be an OIDC client, configured to use Authentik.
  - Redirect URIs for both applications need to be correctly configured in Authentik when creating the OIDC clients.
  - Client IDs and secrets for WordPress and OpenWebUI (generated in Authentik) need to be stored as Kubernetes `Secrets` for the respective applications.

## 6. General Guidance for Copilot Chat

- Prioritize using **IONOS MKS** and **IONOS Managed DBaaS (MariaDB for WordPress, PostgreSQL for Authentik)**.
- When discussing Terraform, focus on `ionoscloud_k8s_cluster`, `ionoscloud_k8s_node_pool`, `ionoscloud_dbaas_mariadb_cluster`, and `ionoscloud_dbaas_postgres_cluster`.
- Help structure YAML for Kubernetes resources (`Deployments`, `Services`, `Ingress`, `PVCs`, `ConfigMaps`, `Secrets`), noting database externalization and Authentik's self-hosted Redis on K8s.
- Emphasize creating Kubernetes `Secrets` for application database connections, sourcing credentials from Terraform outputs of the managed database services.
- Assist in defining probes (`livenessProbe`, `readinessProbe`), resource requests/limits, and labels according to best practices.
- When discussing networking, remind me about MKS pods needing to reach the respective IONOS Managed Database endpoints and how services expose applications internally and externally via Ingress.
- For SSO, guide on the general OIDC flow and what information (client IDs, secrets, redirect URIs) needs to be configured in Authentik and the client applications.
- For the custom "MCP," help think about how this affects Kubernetes `Service` definitions, application configuration, and potential Ingress rules.
- Remind me of best practices for Kubernetes deployments, even in a PoC context (e.g., security contexts, avoiding `latest` tags for images in production, least privilege RBAC).

---
