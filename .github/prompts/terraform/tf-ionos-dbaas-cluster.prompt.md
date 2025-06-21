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
