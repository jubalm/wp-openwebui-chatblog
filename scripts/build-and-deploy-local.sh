#!/bin/bash

# WordPress OpenWebUI Integration - Local Development Script
# 
# This script is for LOCAL DEVELOPMENT ONLY
# For production deployments, use GitHub Actions workflows:
# 1. "Build and Push WordPress Image" - builds both WordPress and Pipeline images
# 2. "Deploy Infrastructure & Applications" - deploys via Terraform

set -e

echo "🚀 Starting LOCAL WordPress-OpenWebUI Integration deployment..."
echo "⚠️  For production, use GitHub Actions workflows instead"

# Configuration
DOCKER_REGISTRY="localhost:5000"  # Update with your registry
PROJECT_NAME="wp-openwebui"
NAMESPACE="admin-apps"

# Build WordPress OAuth2 Pipeline Docker image
echo "📦 Building WordPress OAuth2 Pipeline Docker image..."
cd pipelines
docker build -t ${DOCKER_REGISTRY}/wordpress-oauth-pipeline:latest .
cd ..

# Build WordPress Docker image with integrated plugin
echo "📦 Building WordPress Docker image with OpenWebUI connector plugin..."
cd docker/wordpress
docker build -t ${DOCKER_REGISTRY}/wordpress-openwebui:latest .
cd ../..

# Push to registry (if using external registry)
if [ "$DOCKER_REGISTRY" != "localhost:5000" ]; then
    echo "🚢 Pushing Docker images to registry..."
    docker push ${DOCKER_REGISTRY}/wordpress-oauth-pipeline:latest
    docker push ${DOCKER_REGISTRY}/wordpress-openwebui:latest
fi

# Note: Terraform deployment is handled by GitHub Actions
echo "🏗️  For Terraform deployment, use GitHub Actions:"
echo "   - 'Unified Terraform Deployment' workflow handles infrastructure"
echo "   - Pipeline service will be deployed automatically to platform layer"
echo ""
echo "📝 Local development only - no Terraform deployment"

# Package WordPress plugin (for manual distribution if needed)
echo "📋 Packaging WordPress plugin..."
cd docker/wordpress/plugins/wordpress-openwebui-connector
zip -r wordpress-openwebui-connector.zip . -x "*.git*" "*.DS_Store*"
cd ../../../..

echo "✅ Local build completed successfully!"
echo ""
echo "📌 For production deployment:"
echo "1. Push your changes to the main branch"
echo "2. GitHub Actions will automatically:"
echo "   - Build and push both WordPress and Pipeline service images"
echo "   - Deploy the infrastructure via Terraform"
echo "   - Deploy the Pipeline service to the platform layer"
echo ""
echo "📌 Manual deployment (if needed):"
echo "1. Set GitHub Secrets:"
echo "   - AUTHENTIK_CLIENT_ID"
echo "   - AUTHENTIK_CLIENT_SECRET"
echo "2. Run 'Build and Push WordPress and Pipeline Images' workflow"
echo "3. Run 'Unified Terraform Deployment' workflow"
echo ""
echo "📌 Configuration after deployment:"
echo "1. The WordPress OpenWebUI Connector plugin is pre-installed"
echo "2. Configure OAuth2 in WordPress admin → Settings → OpenWebUI Connector"
echo "3. Generate and register WordPress Application Password"
echo ""
echo "🔧 Troubleshooting:"
echo "- Check pod logs: kubectl logs -n ${NAMESPACE} deployment/wordpress-oauth-pipeline"
echo "- Check service status: kubectl get svc -n ${NAMESPACE}"
echo "- Test pipeline health: curl http://your-openwebui-url/api/wordpress/health"