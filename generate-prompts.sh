#!/bin/bash

# Script to generate GitHub Copilot prompt files for the IONOS MKS PoC
# Aligned with documentation: files in .github/prompts/ with .prompt.md extension

# Base directory for prompts as per documentation
PROMPTS_DIR=".github/prompts"

# Create base and subdirectories
# Note: The documentation implies a flat structure in .github/prompts/ when using the VS Code tool,
# but subdirectories should still work for organization if you manually reference them.
# For maximum compatibility with how VS Code "Chat: Create Prompt" might work,
# you could choose to put them all flat, or use subdirs and reference like:
# #file terraform/tf-ionos-dbaas-cluster.prompt.md
# We'll keep subdirs for now for organization.

mkdir -p "${PROMPTS_DIR}/terraform"
mkdir -p "${PROMPTS_DIR}/kubernetes"
mkdir -p "${PROMPTS_DIR}/apps"

echo "Created directory structure under ${PROMPTS_DIR}"

# --- Terraform Prompts ---

# 1. tf-ionos-dbaas-cluster.prompt.md
cat << 'EOF' > "${PROMPTS_DIR}/terraform/tf-ionos-dbaas-cluster.prompt.md"
# Terraform for IONOS Managed Database Cluster

Help me create Terraform HCL to provision an IONOS Managed `{{db_type}}` cluster (e.g., mariadb, postgres).
- The cluster should be named `{{cluster_name}}`.
- It's intended for application: `{{application_name}}`.
- Use a PoC-appropriate instance size/tier (e.g., `DEV_XS` or smallest available general purpose, check IONOS provider docs for valid values).
- The admin username should be `{{db_admin_user}}`.
- The admin password should be sourced from a new sensitive Terraform variable `{{db_admin_password_var_name}}`.
- The database name to create initially should be `{{db_name}}`.
- Ensure it's located in the primary datacenter region specified in our variables (e.g., `var.ionos_primary_location` or a specific like `de/txl`).
- Output the following:
    - Cluster ID
    - Hostname
    - Port
    - Database Name
    - Admin Username
EOF
echo "Created ${PROMPTS_DIR}/terraform/tf-ionos-dbaas-cluster.prompt.md"

# 2. tf-mks-nodepool.prompt.md
cat << 'EOF' > "${PROMPTS_DIR}/terraform/tf-mks-nodepool.prompt.md"
# Terraform for New IONOS MKS Node Pool

Help me add a new node pool to our existing IONOS MKS cluster (referenced via `ionoscloud_k8s_cluster.main_mks_cluster.id` or similar variable).
- Node pool name: `{{nodepool_name}}`
- Datacenter ID/Location: Should match the main cluster's datacenter.
- Node count: `{{node_count}}` (e.g., 2)
- Instance type/size: `{{instance_type}}` (e.g., `CUBE_S_AMD` or a suitable IONOS SKU for `{{workload_type}}`)
- Kubernetes version should match the cluster's version (or be compatible).
- Add standard labels like `workload-type: {{workload_type_label}}`.
EOF
echo "Created ${PROMPTS_DIR}/terraform/tf-mks-nodepool.prompt.md"

# --- Kubernetes Manifest Prompts ---

# 1. k8s-app-deployment-base.prompt.md
cat << 'EOF' > "${PROMPTS_DIR}/kubernetes/k8s-app-deployment-base.prompt.md"
# Kubernetes Base Application Deployment (Deployment, Service, Ingress)

Generate Kubernetes YAML for deploying `{{app_name}}` in the `{{namespace | default: "poc-apps"}}` namespace.

**1. Deployment:**
- Name: `{{app_name}}-deployment`
- Replicas: `{{replicas | default: 1}}`
- Image: `{{image_name_and_tag}}`
- Container name: `{{app_name}}`
- Container port to expose: `{{container_port}}`
- Include standard labels: `app: {{app_name}}`, `tier: {{tier | default: "application"}}`.
- Add basic liveness and readiness probes for an HTTP endpoint on `{{container_port}}` at path `{{health_check_path | default: "/"}}`.
- If `{{secret_name | optional}}` is specified, mount environment variables from a Secret named `{{secret_name}}`.
- If `{{configmap_name | optional}}` is specified, mount configuration from a ConfigMap named `{{configmap_name}}`.
- If `{{pvc_name | optional}}` is specified for persistent storage, mount a PersistentVolumeClaim named `{{pvc_name}}` at path `{{mount_path}}`.

**2. Service (ClusterIP):**
- Name: `{{app_name}}-service`
- Exposes the Deployment's `{{container_port}}` (as `port`) targeting the container's `{{container_port}}` (as `targetPort`).
- Selector: `app: {{app_name}}`.

**3. Ingress (Optional):**
- If external access is needed:
    - Name: `{{app_name}}-ingress`
    - Hostname: `{{hostname (e.g., app_name.yourdomain.com)}}`
    - Path: `/` (or `{{ingress_path | default: "/"}}`)
    - Service backend: `{{app_name}}-service` on port `{{container_port}}`.
    - Suggest adding TLS configuration using a secret named `{{tls_secret_name | optional}}`.
EOF
echo "Created ${PROMPTS_DIR}/kubernetes/k8s-app-deployment-base.prompt.md"

# 2. k8s-persistent-volume-claim.prompt.md
cat << 'EOF' > "${PROMPTS_DIR}/kubernetes/k8s-persistent-volume-claim.prompt.md"
# Kubernetes PersistentVolumeClaim

Generate YAML for a PersistentVolumeClaim:
- Name: `{{pvc_name}}`
- Namespace: `{{namespace | default: "poc-apps"}}`
- Storage request: `{{storage_size | default: "5Gi"}}`
- Access mode: `{{access_mode | default: "ReadWriteOnce"}}`
- Storage class: Remind me to use the appropriate IONOS CSI storage class (e.g., `ionos-enterprise-hdd` or `ionos-enterprise-ssd`). Check current IONOS documentation for valid storage class names.
EOF
echo "Created ${PROMPTS_DIR}/kubernetes/k8s-persistent-volume-claim.prompt.md"

# 3. k8s-secret-db-connection.prompt.md
cat << 'EOF' > "${PROMPTS_DIR}/kubernetes/k8s-secret-db-connection.prompt.md"
# Kubernetes Secret for Database Connection

Generate YAML for a Kubernetes Secret named `{{secret_name}}` in the `{{namespace | default: "poc-apps"}}` namespace.
This secret will store connection details for a `{{db_type}}` database.
It should contain the following keys, with placeholder values that I will replace from Terraform outputs or manual entry:
- `DB_HOST`: `<placeholder_db_host>`
- `DB_PORT`: `<placeholder_db_port_as_string>`
- `DB_NAME`: `<placeholder_db_name>`
- `DB_USER`: `<placeholder_db_user>`
- `DB_PASSWORD`: `<placeholder_db_password>`

Remind me that all secret values must be base64 encoded if applying the YAML directly.
Alternatively, guide me on using `kubectl create secret generic {{secret_name}} --from-literal=DB_HOST='...' --from-literal=DB_USER='...' ...` for easier creation.
EOF
echo "Created ${PROMPTS_DIR}/kubernetes/k8s-secret-db-connection.prompt.md"

# --- Application Specific Prompts ---

# 1. app-authentik-oidc-client.prompt.md
cat << 'EOF' > "${PROMPTS_DIR}/apps/app-authentik-oidc-client.prompt.md"
# Configuring an OIDC Client in Authentik for {{client_app_name}}

Outline the key information and steps required to configure "{{client_app_name}}" as an OIDC client application in Authentik:

1.  **In Authentik Admin UI (under Applications -> Applications -> Create Application):**
    - Name: `{{client_app_name}}`
    - Slug: (e.g., `{{client_app_name_slug}}`)
    - Provider: Create or select an existing OpenID Connect Provider.

2.  **In Authentik OIDC Provider Settings (associated with the application):**
    - Client type: (e.g., Confidential)
    - Client ID: (Authentik will generate this, e.g., `{{placeholder_client_id}}`)
    - Client Secret: (Authentik will generate this, e.g., `{{placeholder_client_secret}}`) -> Remind me to store this in a K8s Secret for `{{client_app_name}}`.
    - Redirect URIs/Callback URLs (one per line):
        - `https://{{client_app_name_hostname_1}}/path/to/oidc/callback`
        - `https://{{client_app_name_hostname_2}}/another/callback`
    - Scopes: (e.g., `openid email profile`)
    - Signing Key: Select an appropriate key.

3.  **Information to provide to "{{client_app_name}}" configuration:**
    - Authentik Issuer URL / Discovery URL (e.g., `https://authentik.yourdomain.com/application/o/{{provider_slug_or_name}}/`)
    - Client ID (from Authentik).
    - Client Secret (from Authentik, to be loaded from the K8s Secret).

Remind me to ensure the Redirect URIs configured in Authentik exactly match what "{{client_app_name}}" will use and register.
EOF
echo "Created ${PROMPTS_DIR}/apps/app-authentik-oidc-client.prompt.md"

echo ""
echo "All Copilot prompt files generated successfully in ${PROMPTS_DIR} with .prompt.md extension!"
echo "Remember to enable prompt files in your VS Code workspace settings if you haven't already:"
echo "In .vscode/settings.json, add: \"github.copilot.chat.promptFiles\": true (or just \"chat.promptFiles\": true as per docs)"
echo "(Check current VS Code Copilot documentation for the exact settings key if needed)"
