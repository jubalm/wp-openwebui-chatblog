# Explanation of the WordPress Helm Chart Files

This document explains the role of each file within this Helm chart. A Helm chart is a collection of files that describe a related set of Kubernetes resources, allowing you to manage a complex application as a single unit.

### `Chart.yaml`

This is the main metadata file for the chart.

- **Purpose:** It provides information about the chart itself, such as its name (`wordpress`), version (`0.1.0`), and the version of the application it deploys (`appVersion: "6.5"`).
- **Usage:** Helm uses this file to identify and manage the chart.

---

### `values.yaml`

This is the primary configuration file for the chart.

- **Purpose:** It defines all the default values for variables that can be customized during deployment. This makes the chart reusable and configurable.
- **Key Sections:**
  - `image`: Specifies the Docker image, tag, and pull policy for the WordPress container.
  - `service`: Configures the internal Kubernetes service.
  - `ingress`: Defines settings for exposing WordPress to the internet, including hostname and TLS. It's disabled by default.
  - `persistence`: Manages the creation of a `PersistentVolumeClaim` to store WordPress data so it isn't lost when the pod restarts.
  - `site`: Contains the environment variables used by the custom `wp-entrypoint.sh` script to automate the WordPress installation (site URL, admin credentials, etc.).
  - `database`: Holds the connection details for the external MariaDB database. The password is intentionally left blank here and is expected to be supplied securely from a secret.
  - `authentik`: Contains settings for configuring the OIDC plugin to connect with Authentik for Single Sign-On (SSO).

---

### `templates/_helpers.tpl`

This file is a collection of template helpers.

- **Purpose:** It defines reusable snippets of code to keep the main template files clean and to ensure consistency.
- **Key Helpers:**
  - `wordpress.name` and `wordpress.fullname`: Generate the proper names for Kubernetes resources based on the release name and chart name.
  - `wordpress.labels`: Creates a standard set of labels that are applied to every resource created by this chart, which is essential for organization and resource selection.

---

### `templates/deployment.yaml`

This is the core template that defines the WordPress application itself.

- **Purpose:** It creates a Kubernetes `Deployment` resource, which manages the lifecycle of the WordPress pod(s). It ensures that a specified number of replicas are always running.
- **Key Features:**
  - **Pod Definition:** It specifies the container image to use, pulling from `values.yaml`.
  - **Environment Variables:** It injects all the necessary configuration into the container as environment variables. This includes database credentials (from a secret), site setup details, and OIDC settings.
  - **Volume Mounts:** It mounts the persistent volume at `/var/www/html`, which is where WordPress stores its files.

---

### `templates/service.yaml`

This template creates a stable network endpoint for the WordPress deployment.

- **Purpose:** It creates a Kubernetes `Service` resource. This gives the WordPress pods a single, consistent internal DNS name and IP address within the cluster.
- **Usage:** Other applications inside the Kubernetes cluster (like OpenWebUI) can use this service's name (e.g., `my-release-wordpress.tenant-name.svc.cluster.local`) to reliably communicate with WordPress, even if the underlying pods are recreated.

---

### `templates/ingress.yaml`

This template manages external access to the WordPress application.

- **Purpose:** It creates a Kubernetes `Ingress` resource, which defines rules for routing external HTTP/S traffic to the internal WordPress `Service`.
- **Key Features:**
  - **Conditional:** It is only created if `ingress.enabled` is set to `true` in `values.yaml`.
  - **Host-based Routing:** It specifies the public URL (e.g., `wordpress.example.com`) that will point to the WordPress instance.

---

### `templates/pvc.yaml`

This template handles the request for persistent storage.

- **Purpose:** It creates a `PersistentVolumeClaim` (PVC). This requests a piece of physical storage from the cloud provider (via a StorageClass) to store the WordPress data.
- **Usage:** The `Deployment` uses this PVC to ensure that the `/var/www/html` directory is persisted. This is critical for saving user uploads, themes, and plugins. It is only created if `persistence.enabled` is `true`.

---

### `templates/secrets.yaml`

This template manages sensitive information.

- **Purpose:** It creates Kubernetes `Secret` objects to hold confidential data separately from the rest of the configuration.
- **Key Features:**
  - **Database Secret:** It creates a secret named `...-db-credentials` to hold the WordPress database password. The `deployment.yaml` references this secret to inject the password as an environment variable.
  - **OIDC Secret:** It conditionally creates a secret named `...-oidc-credentials` for the Authentik client secret if `authentik.enabled` is `true`.
  - **Encoding:** It uses the `b64enc` function to Base64-encode the secret values, which is required by Kubernetes.
