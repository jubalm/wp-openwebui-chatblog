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
