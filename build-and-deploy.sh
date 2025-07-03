#!/bin/bash

# WordPress OpenWebUI Integration - Build and Deploy Script

set -e

echo "🚀 Starting WordPress-OpenWebUI Integration deployment..."

# Configuration
DOCKER_REGISTRY="localhost:5000"  # Update with your registry
PROJECT_NAME="wp-openwebui"
NAMESPACE="admin-apps"

# Build WordPress OAuth2 Pipeline Docker image
echo "📦 Building WordPress OAuth2 Pipeline Docker image..."
cd pipelines
docker build -t ${DOCKER_REGISTRY}/wordpress-oauth-pipeline:latest .
cd ..

# Push to registry (if using external registry)
if [ "$DOCKER_REGISTRY" != "localhost:5000" ]; then
    echo "🚢 Pushing Docker image to registry..."
    docker push ${DOCKER_REGISTRY}/wordpress-oauth-pipeline:latest
fi

# Update Terraform configuration with image registry
echo "🔧 Updating Terraform configuration..."
sed -i.bak "s|image = \"wordpress-oauth-pipeline:latest\"|image = \"${DOCKER_REGISTRY}/wordpress-oauth-pipeline:latest\"|g" terraform/platform/main.tf

# Apply Terraform changes
echo "🏗️  Applying Terraform configuration..."
cd terraform/platform

# Initialize if needed
if [ ! -d ".terraform" ]; then
    terraform init
fi

# Plan and apply
terraform plan -out=tfplan
terraform apply tfplan

cd ../..

# Package WordPress plugin
echo "📋 Packaging WordPress plugin..."
cd wordpress-plugin
zip -r wordpress-openwebui-connector.zip . -x "*.git*" "*.DS_Store*"
cd ..

echo "✅ Deployment completed successfully!"
echo ""
echo "📌 Next steps:"
echo "1. Download and install the WordPress plugin: wordpress-plugin/wordpress-openwebui-connector.zip"
echo "2. Configure Authentik OAuth2 application with these settings:"
echo "   - Client Type: Confidential"
echo "   - Authorization Grant Type: Authorization Code"
echo "   - Redirect URIs: https://your-wordpress-site.com/wp-admin/options-general.php?page=wp-openwebui-connector&wp_openwebui_oauth_callback=1"
echo "3. Update the Terraform variables with Authentik client credentials:"
echo "   - authentik_client_id"
echo "   - authentik_client_secret"
echo "4. Configure the WordPress plugin with:"
echo "   - OpenWebUI URL: Your OpenWebUI instance URL"
echo "   - OAuth2 Client ID: From Authentik"
echo "   - OAuth2 Client Secret: From Authentik"
echo ""
echo "🔧 Troubleshooting:"
echo "- Check pod logs: kubectl logs -n ${NAMESPACE} deployment/wordpress-oauth-pipeline"
echo "- Check service status: kubectl get svc -n ${NAMESPACE}"
echo "- Test pipeline health: curl http://your-openwebui-url/api/wordpress/health"