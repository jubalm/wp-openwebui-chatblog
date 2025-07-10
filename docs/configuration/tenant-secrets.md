# Automated Tenant Secret Management

This document explains the automated and secure method used in this project to handle database passwords for each WordPress tenant. This approach significantly improves security and reduces manual overhead compared to using a single, shared, manually-managed secret.

---

### The Approach: Per-Tenant Generated Passwords

Instead of using a global, static database password stored in GitHub secrets (e.g., `DB_PASSWORD`), we dynamically generate a unique, strong password for each tenant *during the Terraform execution*.

This is achieved using the following resources in `terraform/tenant/main.tf`:

1.  **`random_password` Resource:**
    ```terraform
    resource "random_password" "db_password" {
      for_each = var.wordpress_tenants
      length   = 16
      special  = true
    }
    ```
    For every tenant defined in the `wordpress_tenants` variable map, Terraform uses the `hashicorp/random` provider to generate a new, 16-character password containing special characters.

2.  **`ionoscloud_mariadb_cluster` Resource:**
    ```terraform
    resource "ionoscloud_mariadb_cluster" "mariadb" {
      for_each = var.wordpress_tenants
      # ... other configuration ...
      credentials {
        username = "wpuser"
        password = random_password.db_password[each.key].result
      }
      # ...
    }
    ```
    The result of the `random_password` resource for the specific tenant (`each.key`) is used to provision the IONOS Managed MariaDB cluster.

3.  **`kubernetes_secret` Resource:**
    ```terraform
    resource "kubernetes_secret" "db_credentials" {
      for_each = var.wordpress_tenants
      # ...
      data = {
        password = base64encode(random_password.db_password[each.key].result)
      }
    }
    ```
    The *exact same* generated password is then immediately used to create the Kubernetes secret within that tenant's namespace.

4.  **`helm_release` Resource:**
    The Helm chart for WordPress is configured to read the database password from this Kubernetes secret.

---

### Key Benefits of This Approach

-   **Enhanced Security:** Each tenant database is completely isolated with its own unique, strong password. A compromise of one tenant's database does not affect any other tenant.
-   **Zero Manual Effort:** There is no need to manually generate, store, or update passwords in GitHub secrets. The entire lifecycle of the password is tied to the tenant's infrastructure.
-   **Improved Scalability:** Adding a new tenant is as simple as adding a new entry to the `wordpress_tenants` variable map in Terraform. The password generation and configuration for the new tenant are handled automatically.
-   **Clean State Management:** When a tenant is removed from the Terraform configuration, its database, its Kubernetes secret, and the password itself are all destroyed, leaving no orphaned credentials.
-   **No Secret Sprawl:** We avoid having to manage a growing list of `DB_PASSWORD_TENANT1`, `DB_PASSWORD_TENANT2`, etc., in our GitHub repository secrets.
