#!/bin/sh

# Authentik deployment automation script
# Loads secrets from .env, renders my-values.yaml, and applies Terraform
# For local/dev use only. Remove when moving to full GitOps/CI.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLATFORM_DIR="$SCRIPT_DIR/../../terraform/platform"

# Load environment variables from .env using best practice for Terraform
if [ -f "$SCRIPT_DIR/.env" ]; then
  echo "Loading environment variables from .env (Terraform best practice)..."
  cd "$SCRIPT_DIR"
  export $(grep -v '^#' .env | xargs)
  cd - > /dev/null
else
  echo "ERROR: .env file not found in $SCRIPT_DIR. Aborting."
  exit 1
fi

# Render my-values.yaml
sh "$SCRIPT_DIR/render-values.sh"

# Apply Terraform
cd "$PLATFORM_DIR"
echo "Running terraform init..."
terraform init

echo "Running terraform apply..."
terraform apply

# Show status and logs after deployment
NAMESPACE="admin-apps"
RELEASE="authentik"

# Helm release status
echo "\n--- Helm release status ---"
helm status $RELEASE -n $NAMESPACE || true

# Pod status
echo "\n--- Pods in $NAMESPACE ---"
kubectl get pods -n $NAMESPACE || true

# Describe Authentik server pod
SERVER_POD=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=authentik,app.kubernetes.io/component=server -o jsonpath='{.items[0].metadata.name}')
if [ -n "$SERVER_POD" ]; then
  echo "\n--- Describe Authentik server pod: $SERVER_POD ---"
  kubectl describe pod -n $NAMESPACE $SERVER_POD || true
  echo "\n--- Logs for Authentik server pod: $SERVER_POD ---"
  kubectl logs -n $NAMESPACE $SERVER_POD || true
else
  echo "No Authentik server pod found."
fi 