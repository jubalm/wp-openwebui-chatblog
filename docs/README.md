# Documentation Navigation

This directory contains comprehensive documentation for the IONOS WordPress-OpenWebUI integration project.

## 📁 Directory Structure

### 📋 Requirements
- **[product-requirements.md](requirements/product-requirements.md)** - Original PoC requirements (historical)
- **[integration-plan.md](requirements/integration-plan.md)** - WordPress-OpenWebUI integration planning

### 🏗️ Architecture
- **[system-architecture.md](architecture/system-architecture.md)** - Complete system architecture with diagrams
- **[technical-overview.md](architecture/technical-overview.md)** - Technical architecture details
- **[multi-tenant-design.md](architecture/multi-tenant-design.md)** - Multi-tenancy design patterns

### 🚀 Deployment
- **[quickstart.md](deployment/quickstart.md)** - Essential developer commands and k9s usage
- **[deployment-strategy.md](deployment/deployment-strategy.md)** - Deployment patterns and networking
- **[terraform-helm-integration.md](deployment/terraform-helm-integration.md)** - Terraform-Helm boundary management
- **[github-actions-approval.md](deployment/github-actions-approval.md)** - Manual approval setup guide
- **[github-env-setup.md](deployment/github-env-setup.md)** - Environment configuration for CI/CD
- **[destruction-workflow.md](deployment/destruction-workflow.md)** - Safe infrastructure teardown
- **[troubleshooting.md](deployment/troubleshooting.md)** - Common issues and fixes

### ⚡ Features
- **[wordpress-openwebui-integration.md](features/wordpress-openwebui-integration.md)** - Main integration guide
- **[content-automation.md](features/content-automation.md)** - Content automation system
- **[tenant-provisioning.md](features/tenant-provisioning.md)** - Multi-tenant management

### ⚙️ Configuration
- **[openai-api.md](configuration/openai-api.md)** - IONOS AI configuration
- **[tenant-secrets.md](configuration/tenant-secrets.md)** - Security patterns for tenant passwords
- **[development-tooling.md](configuration/development-tooling.md)** - Development tools and MCP server

### 📚 Meta
- **[documentation-guide.md](meta/documentation-guide.md)** - Documentation structure and organization
- **[archive/](archive/)** - Historical documentation

## 🔍 Quick Reference

### For Developers
- **Getting Started**: [deployment/quickstart.md](deployment/quickstart.md)
- **Architecture Overview**: [architecture/system-architecture.md](architecture/system-architecture.md)
- **Troubleshooting**: [deployment/troubleshooting.md](deployment/troubleshooting.md)

### For DevOps
- **Deployment Strategy**: [deployment/deployment-strategy.md](deployment/deployment-strategy.md)
- **GitHub Actions**: [deployment/github-actions-approval.md](deployment/github-actions-approval.md)
- **Tenant Management**: [features/tenant-provisioning.md](features/tenant-provisioning.md)

### For Integration
- **WordPress-OpenWebUI**: [features/wordpress-openwebui-integration.md](features/wordpress-openwebui-integration.md)
- **Content Automation**: [features/content-automation.md](features/content-automation.md)
- **AI Configuration**: [configuration/openai-api.md](configuration/openai-api.md)

## 📊 Status and Progress

All implementation status, infrastructure details, known issues, and progress tracking are centralized in the project root:

**[../CLAUDE.md](../CLAUDE.md)** - Single source of truth for project status

---

*For the most current project status, always refer to CLAUDE.md in the project root.*