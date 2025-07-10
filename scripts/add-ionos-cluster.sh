#!/bin/bash

# Check if cluster ID is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <cluster-id>"
    echo "Example: $0 <your-cluster-id>"
    exit 1
fi

CLUSTER_ID="$1"

echo "Adding IONOS cluster: $CLUSTER_ID"

# Get fresh kubeconfig from ionosctl and parse the JSON string
KUBECONFIG_JSON=$(ionosctl k8s kubeconfig get --cluster-id "$CLUSTER_ID" --output=api-json)

if [ $? -ne 0 ]; then
    echo "Error: Failed to get kubeconfig from ionosctl"
    exit 1
fi

# Parse the JSON string (it's a quoted JSON string, so we need to parse it)
PARSED_JSON=$(echo "$KUBECONFIG_JSON" | jq -r '.')

# Extract values using jq
CLUSTER_NAME=$(echo "$PARSED_JSON" | jq -r '.clusters[0].name')
SERVER=$(echo "$PARSED_JSON" | jq -r '.clusters[0].cluster.server')
CA_DATA=$(echo "$PARSED_JSON" | jq -r '.clusters[0].cluster."certificate-authority-data"')
USER_NAME=$(echo "$PARSED_JSON" | jq -r '.users[0].name')
TOKEN=$(echo "$PARSED_JSON" | jq -r '.users[0].user.token')
CONTEXT_NAME=$(echo "$PARSED_JSON" | jq -r '.contexts[0].name')

# Create temporary file for certificate authority data
TEMP_CA_FILE=$(mktemp)
echo "$CA_DATA" | base64 -d > "$TEMP_CA_FILE"

# Add cluster
kubectl config set-cluster "$CLUSTER_NAME" \
  --server="$SERVER" \
  --certificate-authority="$TEMP_CA_FILE" \
  --embed-certs=true

# Add user
kubectl config set-credentials "$USER_NAME" \
  --token="$TOKEN"

# Add context
kubectl config set-context "$CONTEXT_NAME" \
  --cluster="$CLUSTER_NAME" \
  --user="$USER_NAME"

# Clean up temporary file
rm -f "$TEMP_CA_FILE"

echo "Successfully added IONOS cluster context: $CONTEXT_NAME"
echo "To use it: kubectl config use-context $CONTEXT_NAME"