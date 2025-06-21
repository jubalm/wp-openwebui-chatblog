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
