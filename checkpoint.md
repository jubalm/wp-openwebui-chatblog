High-Level Overview


  The entire deployment is managed by the `.github/workflows/deploy.yml`
  GitHub Actions workflow. This workflow is triggered automatically when
  changes are pushed to the main branch in the terraform/, charts/, or
  workflow directories.


  The process is broken down into three main stages, executed in order:
   1. Infrastructure: Provisions the core cloud resources.
   2. Platform: Deploys the shared applications (Authentik, OpenWebUI) onto
      the infrastructure.
   3. Tenant: Deploys the individual WordPress tenant applications.

  ---


  Stage 1: Infrastructure Deployment (plan-infra & apply-infra)


   * What it does: This stage uses Terraform to create the fundamental
     infrastructure in your IONOS Cloud account.
   * Key Steps:
       1. It runs terraform init and terraform plan in the
          terraform/infrastructure/ directory.
       2. This creates the IONOS Managed Kubernetes (MKS) cluster, the node
          pools, and the managed PostgreSQL database required by Authentik.
       3. After you approve the plan, the apply-infra job runs terraform
          apply to build these resources.


  Stage 2: Platform Deployment (plan-platform & apply-platform)


   * What it does: This stage deploys the shared applications onto the
     Kubernetes cluster created in Stage 1. This is where the main issue
     was and where our fix comes into play.
   * Key Steps:
       1. It runs terraform plan and terraform apply in the
          terraform/platform/ directory. This Terraform configuration is
          responsible for deploying the Helm charts for authentik and
          openwebui.
       2. Get Kubeconfig & Secrets: After the Terraform apply, the workflow
          runs a crucial script.
           * It extracts the kubeconfig file from Terraform output to gain
             access to the cluster.
           * It extracts the connection details for the PostgreSQL database
             (host, user, password) that were created in Stage 1.
       3. Create/Update Authentik Secret (The Fix): This is the most
          important step for our problem.
           * It uses kubectl create secret generic authentik-env-secrets to
             create the necessary secret for Authentik directly in the
             admin-apps namespace.
           * It generates a new, random `secret_key` on the fly using
             openssl rand -hex 32.
           * It populates the secret with the PostgreSQL credentials it
             just retrieved from Terraform.
           * The --dry-run=client -o yaml | kubectl apply -f - pattern
             ensures this works for both initial creation and subsequent
             updates without errors.

  How the Fix Works


  The original problem was a conflict:
   * The GitHub Action was trying to create the authentik-env-secrets
     secret with dynamically generated values.
   * The Helm chart was also trying to create the same secret but was using
     the insecure, hardcoded "REPLACE_ME" values from
     charts/authentik/values.yaml.


  Our solution resolves this conflict:
   1. We edited charts/authentik/values.yaml to set `secret.create: false`.
   2. We removed the hardcoded, insecure secret_key and other placeholder
      values from that file.


  Now, the Helm chart will no longer attempt to create the secret. The
  GitHub Actions workflow is the single source of truth, ensuring the
  secret is created correctly with a strong, random key and the proper
  database credentials. The Redis connection error was a symptom of this
  primary issue, as the Authentik application couldn't start properly to
  connect to Redis.


  Stage 3: Tenant Deployment (plan-tenant & apply-tenant)


   * What it does: After the platform is up, this final stage deploys the
     individual WordPress instances.
   * Key Steps:
       1. It runs terraform plan and terraform apply in the
          terraform/tenant/ directory.
       2. This Terraform code reads the list of tenants you have defined
          and, for each one, deploys the wordpress Helm chart into its own
          isolated namespace (wordpress-tenant-<name>).
       3. It also handles creating a dedicated managed MariaDB database for
          each tenant and securely passing the credentials to the
          corresponding WordPress instance.