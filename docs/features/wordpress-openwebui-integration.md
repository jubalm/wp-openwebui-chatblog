# WordPress-OpenWebUI Integration

A secure OAuth2-based integration system that allows OpenWebUI to interact with WordPress using Application Passwords. This implementation follows security best practices by ensuring Application Passwords are never exposed client-side.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Authentik     │    │   OpenWebUI     │    │   WordPress     │
│   (OAuth2/SSO)  │◄──►│   + Pipelines   │◄──►│   + Plugin      │
│   PostgreSQL    │    │   SQLite/PG     │    │   MariaDB       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                     ┌─────────────────┐
                     │   IONOS AI      │
                     │   Platform      │
                     │   (OpenAI API)  │
                     └─────────────────┘
```

## Components

### 1. OpenWebUI Pipelines Service
- **Location**: `pipelines/`
- **Purpose**: Handles OAuth2 flow and secure Application Password storage
- **Features**:
  - OAuth2 authentication with Authentik
  - Encrypted Application Password storage
  - WordPress REST API client
  - RESTful endpoints for WordPress operations

### 2. WordPress Plugin
- **Location**: `docker/wordpress/plugins/wordpress-openwebui-connector/`
- **Purpose**: Provides OAuth2 client and Application Password management
- **Features**:
  - OAuth2 client implementation
  - Admin interface for connection management
  - Application Password registration
  - Connection status monitoring

### 3. Infrastructure
- **Location**: `terraform/platform/`
- **Purpose**: Kubernetes deployment configuration
- **Features**:
  - Pipelines service deployment
  - Persistent storage for SQLite database
  - Ingress configuration
  - Secret management

## Security Features

**Application Passwords never exposed client-side**  
**End-to-end encryption of stored credentials**  
**OAuth2 authentication flow**  
**Token-based API access**  
**Secure secret management**  
**HTTPS everywhere**  

## Setup Instructions

### Prerequisites

- Kubernetes cluster with Helm
- Authentik instance running
- WordPress installation with REST API enabled
- Docker registry access

### 1. Deploy the Infrastructure (Automated)

The pipeline service is automatically deployed via GitHub Actions:

```bash
# Push changes to trigger automated deployment
git push origin main

# Or manually trigger workflows:
# 1. "Build and Push WordPress and Pipeline Images" 
# 2. "Unified Terraform Deployment"
```

**For local development only:**
```bash
./build-and-deploy.sh  # Builds images locally
```

### 2. Configure Authentik OAuth2 Application

1. Go to Authentik Admin → Applications → Providers
2. Create new **OAuth2/OpenID Provider**:
   - **Client Type**: Confidential
   - **Authorization Grant Type**: Authorization Code
   - **Redirect URIs**: `https://your-wordpress-site.com/wp-admin/options-general.php?page=wp-openwebui-connector&wp_openwebui_oauth_callback=1`
3. Note down **Client ID** and **Client Secret**
4. Create Application and bind to provider

### 3. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

```bash
# In GitHub → Settings → Secrets and variables → Actions
AUTHENTIK_CLIENT_ID=your-client-id
AUTHENTIK_CLIENT_SECRET=your-client-secret

# These should already exist for the main platform:
IONOS_TOKEN=your-ionos-token
OPENAI_API_KEY=your-ionos-api-key
CR_USERNAME=your-container-registry-username
CR_PASSWORD=your-container-registry-password
```

### 4. WordPress Plugin (Pre-installed)

The WordPress OpenWebUI Connector plugin is automatically installed and activated when using the custom WordPress Docker image. No manual installation required!

### 5. Configure WordPress Plugin

1. Go to **Settings → OpenWebUI Connector**
2. Configure:
   - **OpenWebUI URL**: Your OpenWebUI instance URL
   - **OAuth2 Client ID**: From Authentik
   - **OAuth2 Client Secret**: From Authentik
3. Save settings

### 6. Connect WordPress to OpenWebUI

1. Click **"Connect to OpenWebUI"**
2. Authenticate via Authentik (SSO)
3. Generate WordPress Application Password:
   - Go to **Users → Profile → Application Passwords**
   - Create new password named "OpenWebUI Connector"
   - Copy the generated password
4. Return to plugin settings and register the Application Password

## API Endpoints

### OAuth2 Endpoints
- `POST /api/wordpress/register-connection` - Register WordPress connection
- `GET /api/wordpress/connections` - Get user's connections
- `DELETE /api/wordpress/connections/{id}` - Delete connection

### WordPress Content Endpoints  
- `GET /api/wordpress/posts?connection_id=xxx` - Get posts
- `POST /api/wordpress/posts` - Create post
- `PUT /api/wordpress/posts/{id}` - Update post
- `DELETE /api/wordpress/posts/{id}` - Delete post
- `GET /api/wordpress/test/{connection_id}` - Test connection

## Usage Examples

### Create a WordPress Post

```python
import httpx

# Authenticate with OpenWebUI
headers = {"Authorization": "Bearer your-openwebui-token"}

# Create post
post_data = {
    "title": "Hello from OpenWebUI",
    "content": "This post was created via the OpenWebUI integration.",
    "status": "draft"
}

response = httpx.post(
    "https://your-openwebui.com/api/wordpress/posts",
    headers=headers,
    params={"connection_id": "your-connection-id"},
    json=post_data
)
```

### Get WordPress Posts

```python
response = httpx.get(
    "https://your-openwebui.com/api/wordpress/posts",
    headers=headers,
    params={
        "connection_id": "your-connection-id",
        "per_page": 10,
        "status": "publish"
    }
)
posts = response.json()
```

## Development

### Local Development Setup

```bash
# Start pipeline locally
cd pipelines
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python wordpress_oauth.py

# The service will be available at http://localhost:9099
```

### Environment Variables

```bash
# Required
WORDPRESS_ENCRYPTION_KEY=your-32-char-key
AUTHENTIK_URL=https://your-authentik-instance
AUTHENTIK_CLIENT_ID=client-id
AUTHENTIK_CLIENT_SECRET=client-secret
```

## Troubleshooting

### Common Issues

1. **Plugin can't connect to OpenWebUI**
   - Check OpenWebUI URL is correct and accessible
   - Verify OAuth2 client credentials
   - Check Authentik redirect URIs

2. **Application Password registration fails**
   - Ensure WordPress REST API is enabled
   - Check Application Password format
   - Verify WordPress user permissions

3. **Pipeline service not starting**
   - Check Kubernetes logs: `kubectl logs -n admin-apps deployment/wordpress-oauth-pipeline`
   - Verify secrets are correctly configured
   - Check persistent volume claims

### Debug Information

The WordPress plugin provides debug information in the admin interface:
- Plugin version and configuration
- Connection status
- Site URLs and redirect URIs
- Environment details

### Health Checks

```bash
# Check pipeline health
curl https://your-openwebui.com/api/wordpress/health

# Check Kubernetes resources
kubectl get all -n admin-apps
kubectl describe deployment wordpress-oauth-pipeline -n admin-apps
```

## Security Considerations

- Application Passwords are encrypted at rest using AES-256
- All communication uses HTTPS
- OAuth2 tokens are validated with Authentik
- Database access is restricted to the pipeline service
- WordPress API access uses least-privilege principles

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details.