#!/bin/sh

# Source .env from project root if it exists
PROJECT_ROOT="$(dirname "$0")/../.."
if [ -f "$PROJECT_ROOT/.env" ]; then
  set -a
  . "$PROJECT_ROOT/.env"
  set +a
fi

# Get PostgreSQL connection details from Terraform output
PG_OUTPUT=$(terraform -chdir="$PROJECT_ROOT/terraform/platform" output -json | jq -r '.postgres_connection.value')
export POSTGRES_HOST=$(echo "$PG_OUTPUT" | jq -r '.host')
export POSTGRES_PORT=$(echo "$PG_OUTPUT" | jq -r '.port')
export POSTGRES_USERNAME=$(echo "$PG_OUTPUT" | jq -r '.username')
export POSTGRES_PASSWORD=$(echo "$PG_OUTPUT" | jq -r '.password')
export POSTGRES_DATABASE=$(echo "$PG_OUTPUT" | jq -r '.database')

# Usage: export your secrets as env vars, then run this script
# Example:
#   export POSTGRES_HOST=... POSTGRES_PASSWORD=... AUTHENTIK_SECRET_KEY=... AUTHENTIK_ADMIN_PASSWORD=...
#   ./render-values.sh

TEMPLATE="$(dirname "$0")/values.template.yaml"
OUTPUT="$(dirname "$0")/my-values.yaml"

envsubst < "$TEMPLATE" > "$OUTPUT"
echo "Rendered $OUTPUT from $TEMPLATE" 