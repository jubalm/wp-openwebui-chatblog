# WordPress Content Automation Guide

## 🚀 Overview

The WordPress Content Automation system provides seamless integration between OpenWebUI and WordPress, enabling automated content publishing with intelligent processing and workflow management.

## 🏗️ Architecture

```
OpenWebUI User → OpenWebUI Pipeline → Content Automation Service → WordPress API
     ↓                    ↓                        ↓                      ↓
📝 Chat/Content    🔄 Intent Detection    ⚙️ Content Processing    📰 Published Post
```

### Components

1. **OpenWebUI WordPress Pipeline** (`openwebui_wordpress_pipeline.py`)
   - Integrates directly with OpenWebUI conversations
   - Detects publishing intent from user messages
   - Extracts content and titles from chat context

2. **Content Automation Service** (`content_automation.py`)
   - Manages content publishing workflows
   - Provides intelligent content processing
   - Handles retry logic and error recovery

3. **WordPress OAuth Pipeline** (`wordpress_oauth.py`)
   - Secure WordPress API integration
   - OAuth2 authentication with Authentik
   - RESTful API endpoints for content management

## 📋 Features

### ✅ Automated Content Processing
- **Auto-generated excerpts** from content
- **Smart tag extraction** using content analysis
- **Table of contents** generation for long content
- **SEO optimization** with meta titles and descriptions
- **Content formatting** (Markdown to HTML conversion)

### ✅ Workflow Management
- **Async processing** with status tracking
- **Scheduled publishing** for future dates
- **Retry logic** with exponential backoff
- **Multi-user support** with OAuth2 authentication
- **Content type templates** (blog_post, article, tutorial, FAQ, documentation)

### ✅ OpenWebUI Integration
- **Natural language triggers** ("publish to WordPress", "create blog post")
- **Context-aware content extraction** from conversations
- **Automatic title generation** from content or user intent
- **Real-time workflow feedback** in chat interface

## 🎯 Content Types

### Blog Post
- **Format**: Standard blog format
- **Features**: Auto-tagging, excerpts
- **Categories**: ["Blog"]
- **Use case**: Regular blog content, updates, news

### Article
- **Format**: Long-form content
- **Features**: Auto-excerpts, detailed tagging
- **Categories**: ["Articles"]
- **Use case**: In-depth analysis, research pieces

### Tutorial
- **Format**: Step-by-step guide
- **Features**: Table of contents, auto-excerpts, enhanced tagging
- **Categories**: ["Tutorials", "How-to"]
- **Use case**: Educational content, guides, walkthroughs

### FAQ
- **Format**: Question-answer format
- **Features**: Basic tagging, no auto-excerpts
- **Categories**: ["FAQ"]
- **Use case**: Support content, common questions

### Documentation
- **Format**: Technical documentation
- **Features**: Table of contents, auto-excerpts, technical tagging
- **Categories**: ["Documentation"]
- **Use case**: API docs, technical guides, specifications

## 🔧 API Endpoints

### Content Workflows

#### Create Workflow
```http
POST /api/content/workflows
Authorization: Bearer {oauth_token}
Content-Type: application/json

{
  "title": "My Blog Post",
  "content": "<h2>Introduction</h2><p>Content here...</p>",
  "content_type": "blog_post",
  "connection_id": "wp_connection_id",
  "tags": ["automation", "wordpress"],
  "categories": ["Technology"],
  "publish_immediately": false,
  "scheduled_publish_time": "2025-07-06T10:00:00Z",
  "seo_title": "SEO Optimized Title",
  "seo_description": "Meta description for SEO"
}
```

#### List Workflows
```http
GET /api/content/workflows?status=completed
Authorization: Bearer {oauth_token}
```

#### Get Workflow Status
```http
GET /api/content/workflows/{workflow_id}
Authorization: Bearer {oauth_token}
```

#### Cancel Workflow
```http
POST /api/content/workflows/{workflow_id}/cancel
Authorization: Bearer {oauth_token}
```

#### Retry Failed Workflow
```http
POST /api/content/workflows/{workflow_id}/retry
Authorization: Bearer {oauth_token}
```

### Content Templates
```http
GET /api/content/templates
```

Returns available content types and their configurations.

## 🎮 Usage Examples

### OpenWebUI Chat Integration

**User Message:**
```
"Please publish this blog post about AI automation to WordPress"
```

**Pipeline Response:**
```
🚀 WordPress Publishing Pipeline Activated

Title: AI Automation in Modern Workflows
Content Type: blog_post
Auto-publish: No (Draft)

✅ Publishing Workflow Created Successfully!

Workflow ID: abc123-def456-ghi789
Status: processing

💡 You can check the publishing status using the workflow ID.
```

### Direct API Usage

```python
import httpx

# Create a blog post workflow
workflow_data = {
    "title": "Getting Started with Content Automation",
    "content": """
    <h2>Introduction</h2>
    <p>Content automation streamlines the publishing process...</p>
    <h2>Benefits</h2>
    <p>Automated workflows provide several advantages...</p>
    """,
    "content_type": "tutorial",
    "connection_id": "my_wp_connection",
    "publish_immediately": True,
    "tags": ["automation", "tutorial", "wordpress"]
}

async with httpx.AsyncClient() as client:
    response = await client.post(
        "http://pipeline-service/api/content/workflows",
        json=workflow_data,
        headers={"Authorization": "Bearer your_oauth_token"}
    )
    
    workflow = response.json()
    print(f"Workflow created: {workflow['id']}")
```

## ⚙️ Configuration

### OpenWebUI Pipeline Settings

Configure the pipeline valves in OpenWebUI:

```python
valves = {
    "WORDPRESS_CONNECTION_ID": "your_wp_connection_id",
    "AUTO_PUBLISH": False,  # True for immediate publish, False for draft
    "CONTENT_TYPE": "blog_post",  # blog_post, article, tutorial, faq, documentation
    "AUTO_GENERATE_TAGS": True,
    "AUTO_GENERATE_EXCERPT": True,
    "ADD_TABLE_OF_CONTENTS": False,
    "DEFAULT_CATEGORIES": "Blog,Technology"
}
```

### Content Processing Templates

Templates define how different content types are processed:

```python
content_templates = {
    ContentType.TUTORIAL: {
        "wordpress_format": "standard",
        "default_categories": ["Tutorials", "How-to"],
        "auto_excerpt": True,
        "auto_tags": True,
        "add_table_of_contents": True
    }
}
```

## 🔍 Monitoring and Debugging

### Workflow Status Tracking

Workflows progress through these states:
- `pending`: Waiting to be processed
- `processing`: Currently being processed
- `completed`: Successfully published
- `failed`: Processing failed (can be retried)
- `cancelled`: User cancelled the workflow

### Error Handling

The system includes comprehensive error handling:
- **Authentication errors**: Invalid OAuth tokens
- **WordPress API errors**: Connection issues, permission problems
- **Content validation errors**: Missing required fields
- **Network errors**: Timeouts, connectivity issues

### Retry Logic

Failed workflows are automatically retried with exponential backoff:
- **Max retries**: 3 attempts
- **Delay calculation**: `min(300, 30 * (2 ^ retry_count))` seconds
- **Manual retry**: Available through API after max retries exceeded

## 🛠️ Development and Deployment

### Local Development

1. **Install dependencies**:
   ```bash
   pip install -r pipelines/requirements.txt
   ```

2. **Run the service**:
   ```bash
   cd pipelines
   python wordpress_oauth.py
   ```

3. **Test endpoints**:
   ```bash
   curl http://localhost:9099/health
   curl http://localhost:9099/api/content/templates
   ```

### Deployment

1. **Build Docker image**:
   ```bash
   docker build -t wordpress-oauth-pipeline:latest pipelines/
   ```

2. **Deploy to Kubernetes**:
   ```bash
   kubectl apply -f pipeline-deployment.yaml
   ```

3. **Verify deployment**:
   ```bash
   kubectl get pods -n admin-apps | grep wordpress-oauth-pipeline
   kubectl logs -n admin-apps deployment/wordpress-oauth-pipeline
   ```

### Testing

Run the automated test suite:
```bash
./scripts/test-content-automation.sh
```

## 🔐 Security Considerations

- **OAuth2 Authentication**: All API endpoints require valid OAuth tokens
- **User Isolation**: Workflows are isolated by user ID
- **Encrypted Storage**: WordPress credentials stored with encryption
- **Input Validation**: Content and metadata validated before processing
- **Rate Limiting**: Consider implementing rate limits for production use

## 📈 Performance Optimization

- **Async Processing**: All content operations are asynchronous
- **Caching**: Consider caching WordPress API responses
- **Background Tasks**: Long-running workflows don't block API responses
- **Resource Limits**: Set appropriate CPU/memory limits in Kubernetes

## 🎯 Future Enhancements

### Planned Features
- **Social media integration** for cross-platform publishing
- **Content versioning** and revision tracking
- **Advanced SEO analysis** with suggestions
- **Content collaboration** workflows
- **Analytics integration** for performance tracking
- **Template customization** UI
- **Bulk operations** for multiple posts
- **Content scheduling** calendar interface

### Integration Opportunities
- **AI content enhancement** with GPT-based improvements
- **Image optimization** and automatic alt-text generation
- **Multi-language support** with translation workflows
- **Content approval** workflows for teams
- **Backup and sync** with external storage

## 📞 Support and Troubleshooting

### Common Issues

1. **"Invalid authentication credentials"**
   - Verify OAuth token is valid and not expired
   - Check Authentik SSO configuration

2. **"WordPress connection not found"**
   - Ensure WordPress connection is registered
   - Verify connection ID is correct

3. **"Content publishing failed"**
   - Check WordPress API accessibility
   - Verify WordPress user permissions
   - Review WordPress application password

4. **"Workflow stuck in processing"**
   - Check pipeline service logs
   - Verify WordPress API response times
   - Consider manual retry

### Debug Commands

```bash
# Check pipeline service health
kubectl logs -n admin-apps deployment/wordpress-oauth-pipeline

# Test WordPress API
curl -H "Host: wordpress-tenant1.local" \
  http://85.215.220.121/wp-json/wp/v2/

# Test OAuth2 flow
curl -H "Host: openwebui.local" \
  http://85.215.220.121/oauth/oidc/login -I

# List active workflows
curl -H "Authorization: Bearer token" \
  http://pipeline-service/api/content/workflows
```

---

## 📄 License and Attribution

This content automation system is part of the WordPress-OpenWebUI integration project. 

**Generated with [Claude Code](https://claude.ai/code)**