# Infrastructure Status

> **Last Updated**: Template for infrastructure deployment  
> **Status**: Not deployed - Configuration ready

## Current Infrastructure Details

### IONOS Cloud Resources
- **Cluster ID**: `<cluster-id>`
- **LoadBalancer IP**: `<loadbalancer-ip>`
- **Region**: DE-TXL (Germany - Berlin)

### Database Connections
- **PostgreSQL Cluster**: `<postgresql-endpoint>`
  - Purpose: Authentik SSO backend
  - Status: To be deployed
  - Database: `authentik`
  
- **MariaDB Cluster**: `<mariadb-endpoint>`
  - Purpose: WordPress database backend
  - Status: To be deployed
  - Database: `wordpress_tenant1`

### Network Configuration
- **LoadBalancer**: External IP `<loadbalancer-ip>`
- **Ingress Controller**: NGINX Ingress
- **Service Endpoints**:
  - `wordpress-tenant1.local` → LoadBalancer
  - `openwebui.local` → LoadBalancer
  - `authentik.local` → LoadBalancer

### Storage
- **S3 Storage**: IONOS S3-compatible object storage
- **Persistent Volumes**: 
  - WordPress data: 10Gi
  - OpenWebUI data: 10Gi
  - Pipeline data: 1Gi

### AI Integration
- **AI Provider**: IONOS OpenAI API
- **Endpoint**: `https://openai.inference.de-txl.ionos.com/v1`
- **Integration**: OpenWebUI configuration for IONOS AI service
- **Status**: Configuration ready (Ollama replaced for better resource efficiency)

## Architecture Diagram
```
IONOS Cloud Infrastructure (Ready for Deployment)
├── MKS Cluster (<cluster-id>)
├── PostgreSQL (<postgresql-endpoint>)
├── MariaDB (<mariadb-endpoint>)
└── LoadBalancer (<loadbalancer-ip>)

Platform Services (Configuration Ready)
├── Authentik SSO (server + worker)
├── Redis Session Store
├── NGINX Ingress Controller
└── Secret Management

Application Layer (Configuration Ready)
├── WordPress (tenant1)
├── OpenWebUI
├── IONOS AI Integration
└── Database Connections
```

## Resource Planning
- **Cluster Nodes**: 3 nodes (4 cores, 8GB RAM, 100GB SSD each)
- **Total CPU**: 12 vCPUs planned
- **Total Memory**: 24GB RAM planned
- **Total Storage**: 300GB SSD planned
- **Expected Usage**: ~15% CPU, ~20% Memory, ~30% Storage

## High Availability Configuration
- **Database Clusters**: Managed HA by IONOS
- **Application Pods**: Multiple replicas where applicable
- **LoadBalancer**: IONOS-managed with health checks
- **Storage**: Replicated S3 storage

## Security Configuration
- **Network Policies**: Implemented
- **TLS Certificates**: Let's Encrypt (planned)
- **Secrets Management**: Kubernetes secrets
- **RBAC**: Configured for service accounts

## Monitoring & Observability
- **Metrics**: Prometheus-ready (deployment pending)
- **Logging**: Stdout/stderr to container logs
- **Health Checks**: Configured for all services
- **Alerts**: To be configured

## Backup Strategy
- **Databases**: IONOS managed backups
- **Application Data**: PVC snapshots (planned)
- **Configuration**: Git-backed IaC
- **Secrets**: Encrypted backups (planned)