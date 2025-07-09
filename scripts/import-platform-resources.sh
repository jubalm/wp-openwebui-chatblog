#!/bin/bash

# Import existing platform resources into Terraform state
# This resolves state drift caused by manual resource creation

cd terraform/platform

echo "🔧 Importing existing platform resources into Terraform state..."

# Source environment variables
source ../../.env

# Set environment variables for Terraform
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
export TF_VAR_ionos_token="$TF_VAR_ionos_token"
export TF_VAR_openai_api_key="$TF_VAR_openai_api_key"
export TF_VAR_authentik_client_id="wordpress-client"
export TF_VAR_authentik_client_secret="wordpress-secret-2025"

echo "📋 Importing kubernetes_service.wordpress_oauth_pipeline..."
terraform import kubernetes_service.wordpress_oauth_pipeline admin-apps/wordpress-oauth-pipeline || echo "❌ Failed to import service"

echo "📋 Importing kubernetes_persistent_volume_claim.wordpress_oauth_data..."
terraform import kubernetes_persistent_volume_claim.wordpress_oauth_data admin-apps/wordpress-oauth-data || echo "❌ Failed to import PVC"

echo "📋 Importing kubernetes_secret.wordpress_oauth_env..."
terraform import kubernetes_secret.wordpress_oauth_env admin-apps/wordpress-oauth-env-secrets || echo "❌ Failed to import secret"

echo "📋 Importing helm_release.authentik..."
terraform import helm_release.authentik admin-apps/authentik || echo "❌ Failed to import helm release"

echo "✅ Import process completed. Running terraform plan to verify..."
terraform plan

echo "🎉 Platform resource import complete!"