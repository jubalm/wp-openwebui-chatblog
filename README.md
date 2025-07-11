# IONOS WordPress & OpenWebUI Integration Platform

> **Status**: Configuration Ready | **Version**: 2.1 | **Template**: Infrastructure as Code

A multi-tenant platform configuration that integrates WordPress and OpenWebUI with centralized SSO authentication, enabling AI-powered content creation and management workflows on IONOS Cloud infrastructure. Configured with IONOS AI services for enhanced performance and scalability.

## 🚀 Quick Start

```bash
# Get cluster access
ionosctl k8s kubeconfig get --cluster-id <cluster-id>
export KUBECONFIG=./kubeconfig.yaml

# Verify deployment
kubectl get pods -A

# Test services
curl -H "Host: wordpress-tenant1.local" http://<loadbalancer-ip>/
curl -H "Host: openwebui.local" http://<loadbalancer-ip>/

# Run integration tests
./tests/scripts/test-integration.sh

# Manage tenants
./scripts/tenant-management.sh list
```

## ✨ Key Features

- **Multi-Tenant WordPress**: Isolated instances with dedicated databases
- **AI Content Generation**: OpenWebUI integration with IONOS OpenAI API for content creation
- **Single Sign-On**: Authentik SSO with OAuth2/OIDC for all services
- **Content Automation**: Intelligent pipeline for content processing and SEO
- **Infrastructure as Code**: Fully automated deployment with Terraform
- **Cloud Native**: Built on IONOS MKS with managed databases

## 📊 Configuration Status

| Component | Status | Details |
|-----------|--------|---------|
| **Infrastructure** | 🔧 Ready for Deployment | IONOS MKS cluster configuration with managed databases |
| **SSO Authentication** | 🔧 Configuration Ready | Authentik with OAuth2 providers configured |
| **WordPress Platform** | 🔧 Template Ready | Multi-tenant configuration with MCP plugin |
| **OpenWebUI** | 🔧 Configuration Ready | OAuth2 integration, IONOS OpenAI API configured |
| **Content Pipeline** | 🔧 Needs Configuration | Automated content workflow templates |
| **CI/CD** | 🔧 Implementation Needed | GitHub Actions automation templates |

## 🏗️ Architecture Overview

```
IONOS Cloud (<loadbalancer-ip>)
├── WordPress (wordpress-tenant1.local)
├── OpenWebUI (openwebui.local)
├── Authentik SSO (authentik.local)
├── PostgreSQL (Authentik backend)
├── MariaDB (WordPress backend)
└── Content Pipeline Service
```

For detailed architecture, see: [Architecture Documentation](docs/ARCHITECTURE_STATUS.md)

## 📚 Documentation

- **[Project Requirements Plan (PRP)](PRP.md)** - Comprehensive requirements and implementation status
- **[Developer Quickstart](docs/DEVELOPER_QUICKSTART.md)** - Essential commands and procedures
- **[Infrastructure Status](docs/INFRASTRUCTURE_STATUS.md)** - Current infrastructure details
- **[Implementation Status](docs/IMPLEMENTATION_STATUS.md)** - What's built vs planned
- **[Technical Overview](docs/3.TECHNICAL_OVERVIEW.md)** - Detailed technical architecture
- **[OpenAI API Configuration](docs/OPENAI_API_CONFIGURATION.md)** - IONOS OpenAI API setup (replaces Ollama)

## 🚀 Deployment

### Prerequisites

1. **IONOS Account** with access to:
   - Managed Kubernetes Service (MKS)
   - Managed Database clusters
   - S3-compatible storage
   
2. **Tools Required**:
   - `ionosctl` - IONOS CLI
   - `kubectl` - Kubernetes CLI
   - `terraform` - Infrastructure as Code
   - `docker` - Container management

### Quick Deployment

```bash
# Clone repository
git clone https://github.com/your-org/wp-openwebui
cd wp-openwebui

# Deploy infrastructure
cd terraform/infrastructure
terraform init && terraform apply

# Deploy platform
cd ../platform
terraform init && terraform apply

# Verify deployment
kubectl get pods -A
```

## 🔧 Configuration

### Service URLs
- **WordPress**: http://wordpress-tenant1.local (via LoadBalancer)
- **OpenWebUI**: http://openwebui.local (via LoadBalancer)
- **Authentik Admin**: http://authentik.local (via LoadBalancer)

### OAuth2 Credentials
- **WordPress Client**: `wordpress-client` / `wordpress-secret-2025`
- **OpenWebUI Client**: `openwebui-client` / `openwebui-secret-2025`

### Admin Access
Authentik admin recovery token:
```
/recovery/use-token/cw3mx6Wp7CqGHizn4aOGJNkwgrBTuiRZf4YhQ9pOHe5iBcbOnxsi9ZwrZ8vG/
```

## 🔧 Implementation Tasks

1. **Pipeline Configuration**: Python module dependency configuration needed
   - Resolution steps available in [Implementation Status](docs/IMPLEMENTATION_STATUS.md#known-issues-and-workarounds)

2. **OAuth2 Frontend**: SSO button integration for OpenWebUI
   - Backend configured, frontend integration implementation needed

## 🛠️ Platform Management

### Multi-Tenant Operations
```bash
# Create a new tenant
./scripts/tenant-management.sh create my-company 'My Company' admin@mycompany.com pro

# Scale tenant resources
./scripts/tenant-management.sh scale my-company enterprise

# Test tenant health
./scripts/tenant-management.sh test my-company
```

### Testing & Validation
```bash
# Run full integration tests
./tests/scripts/test-integration.sh

# Test SSO integration
./tests/scripts/test-sso-integration.sh

# Run interactive demo
./tests/scripts/demo-tenant-system.sh
```

See [Scripts Documentation](scripts/README.md) for complete management capabilities.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **IONOS Cloud** for infrastructure services
- **Authentik** for enterprise SSO solution
- **OpenWebUI** community for AI chat interface
- **WordPress** ecosystem for extensible CMS

---

*For AI assistance context, see [CLAUDE.md](CLAUDE.md)*