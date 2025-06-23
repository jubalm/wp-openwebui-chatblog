#!/bin/sh

# Usage: export your secrets as env vars, then run this script
# Example:
#   export POSTGRES_HOST=... POSTGRES_PASSWORD=... AUTHENTIK_SECRET_KEY=... AUTHENTIK_ADMIN_PASSWORD=...
#   ./render-values.sh

TEMPLATE="$(dirname "$0")/values.template.yaml"
OUTPUT="$(dirname "$0")/my-values.yaml"

envsubst < "$TEMPLATE" > "$OUTPUT"
echo "Rendered $OUTPUT from $TEMPLATE" 