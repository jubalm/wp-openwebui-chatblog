# Deployment & Networking Strategies

This document outlines the networking and deployment strategies for the platform, covering the default IP-based access, custom domain support for tenants, and the process for securing the entire platform with a global domain and SSL/TLS.

## 1. Default: IP-Based Access

By default, the platform is designed to be fully functional without requiring any domain names. All services are exposed through a single public IP address, managed by the `ingress-nginx` LoadBalancer.

The Ingress Controller acts as a traffic router, directing requests to the appropriate backend service based on the URL path.

- **Single Entrypoint:** All traffic enters through the public IP of the `ingress-nginx` service.
- **Path-Based Routing:** The URL path determines the destination service.

**Default URL Structure:**
- **Authentik:** `http://<PUBLIC_IP>/`
- **OpenWebUI:** `http://<PUBLIC_IP>/openwebui/`
- **WordPress Tenant:** `http://<PUBLIC_IP>/wordpress/<tenant-name>/`

This model is simple, cost-effective, and ideal for the PoC stage and for tenants who do not have a custom domain.

## 2. Strategy: Supporting Custom Tenant Domains

When a tenant wishes to use their own domain name (e.g., `blog.theircompany.com`), they cannot simply CNAME it to a subpath. The platform uses **host-based routing** to support this.

### Workflow

1.  **Tenant DNS Configuration:**
    - The tenant must create an **`A` record** in their DNS provider's settings.
    - This record must point their custom domain to the public IP address of the platform's `ingress-nginx` LoadBalancer.
    - **Example:** `blog.theircompany.com` -> `A` record -> `<PUBLIC_IP>`

2.  **Platform Infrastructure Update:**
    - The Ingress resource for the specific WordPress tenant must be updated to recognize the new hostname.
    - This is achieved by adding a `customDomain` value to the tenant's Helm release configuration in `terraform/tenant/main.tf`.

    ```terraform
    # Example in terraform/tenant/main.tf
    resource "helm_release" "wordpress_tenant" {
      # ... other config
      values = [
        # ... other values
        yamlencode({
          # This value is used by the Ingress template
          customDomain = "blog.theircompany.com"
        })
      ]
    }
    ```
    - The WordPress Helm chart's `ingress.yaml` template must be configured to use this value to create a host-based routing rule. When the `customDomain` is present, the Ingress rule will match traffic based on the `Host` header of the incoming request.

## 3. Strategy: Securing the Platform with a Global Domain & SSL/TLS

For a production-ready deployment, the entire platform should be secured under a registered domain with SSL/TLS certificates. This is accomplished using **cert-manager**, a Kubernetes add-on that automates the management and renewal of SSL certificates from providers like Let's Encrypt.

### Implementation Plan

#### Step 1: Point Domain to Load Balancer IP

In your DNS provider, create `A` records for all the subdomains you intend to use, pointing them to the public IP of the `ingress-nginx` LoadBalancer.

- `auth.yourplatform.com` -> `A` record -> `<PUBLIC_IP>`
- `ui.yourplatform.com` -> `A` record -> `<PUBLIC_IP>`
- etc.

#### Step 2: Install `cert-manager`

Add the `cert-manager` Helm chart to the cluster via `terraform/platform/main.tf`.

```terraform
# In terraform/platform/main.tf
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.14.5" # Use a specific, recent version

  # This is critical for cert-manager to function correctly
  set {
    name  = "installCRDs"
    value = "true"
  }
}
```

#### Step 3: Create a `ClusterIssuer`

A `ClusterIssuer` configures how `cert-manager` will obtain certificates. This is a one-time setup. Create a file (e.g., `k8s/cluster-issuer.yaml`) and apply it to the cluster.

```yaml
# k8s/cluster-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-admin-email@yourplatform.com # Use a real email for expiry notices
    privateKeySecretRef:
      name: letsencrypt-prod-private-key
    solvers:
    - http01:
        ingress:
          class: nginx # Tells cert-manager to use NGINX for the validation challenge
```

This can be applied with `kubectl apply -f k8s/cluster-issuer.yaml` or using a Terraform `kubernetes_manifest` resource.

#### Step 4: Update Ingress Resources for TLS

Modify each service's Ingress resource to request and use a certificate.

**Example: Updating the Authentik Ingress in `terraform/platform/main.tf`**

```terraform
resource "kubernetes_ingress_v1" "authentik_ingress" {
  metadata {
    name      = "authentik-ingress"
    namespace = "admin-apps"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      # 1. Tell cert-manager to issue a certificate for this Ingress
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod" 
    }
  }
  spec {
    # 2. Define the TLS configuration
    tls {
      hosts = [
        "auth.yourplatform.com"
      ]
      # cert-manager will create and manage this secret
      secretName = "authentik-tls-secret" 
    }
    rule {
      # 3. Route based on the hostname
      host = "auth.yourplatform.com"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "authentik"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
```

When these changes are applied, `cert-manager` automatically handles the entire lifecycle of the SSL certificate, enabling HTTPS for the service.
