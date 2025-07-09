# Developer Quickstart Guide

> **Last Updated**: July 8, 2025  
> **Purpose**: Essential commands and procedures for developers

## Prerequisites
- IONOS CLI (`ionosctl`) installed
- `kubectl` installed
- Docker installed (for local development)
- GitHub CLI (`gh`) installed (optional)

## Environment Setup

### 1. Get Cluster Access
```bash
# Download kubeconfig
ionosctl k8s kubeconfig get --cluster-id 354372a8-cdfc-4c4c-814c-37effe9bf8a2

# Set environment variable
export KUBECONFIG=./kubeconfig.yaml

# Verify connection
kubectl get nodes
```

### 2. Essential Commands

#### Service Health Checks
```bash
# Check all pods
kubectl get pods -A

# Check specific services
kubectl get pods -A | grep -E "(wordpress|openwebui|authentik)"

# Service endpoints test
curl -H "Host: wordpress-tenant1.local" http://85.215.220.121/wp-json/wp/v2/
curl -H "Host: openwebui.local" http://85.215.220.121/api/config
curl -H "Host: authentik.local" http://85.215.220.121/ -I
```

#### Port Forwarding (Local Access)
```bash
# OpenWebUI
kubectl port-forward -n admin-apps svc/open-webui 8080:80
# Access: http://localhost:8080

# Authentik
kubectl port-forward -n admin-apps svc/authentik 9001:80
# Access: http://localhost:9001

# WordPress
kubectl port-forward -n wordpress-tenant1 svc/wordpress 8081:80
# Access: http://localhost:8081
```

#### Logs and Debugging
```bash
# View pod logs
kubectl logs -n admin-apps deployment/open-webui
kubectl logs -n admin-apps deployment/authentik-server
kubectl logs -n wordpress-tenant1 deployment/wordpress

# Follow logs
kubectl logs -f -n admin-apps deployment/wordpress-oauth-pipeline

# Debug pod issues
kubectl describe pod -n admin-apps <pod-name>
kubectl exec -it -n admin-apps <pod-name> -- /bin/bash
```

## Common Development Tasks

### 1. Deploy Changes
```bash
# Apply Terraform changes
cd terraform/infrastructure
terraform plan
terraform apply

cd ../platform
terraform plan
terraform apply

# Apply Kubernetes manifests
kubectl apply -f manifests/
```

### 2. Update Secrets
```bash
# View secret
kubectl get secret -n admin-apps openwebui-env-secrets -o yaml

# Edit secret
kubectl edit secret -n admin-apps openwebui-env-secrets

# Create from file
kubectl create secret generic my-secret --from-env-file=.env -n admin-apps
```

### 3. Build and Push Docker Images
```bash
# Login to IONOS registry
docker login wp-openwebui.cr.de-fra.ionos.com

# Build image
cd docker/wordpress
docker build -t wp-openwebui.cr.de-fra.ionos.com/jubalm/ionos/poc/wordpress:latest .

# Push image
docker push wp-openwebui.cr.de-fra.ionos.com/jubalm/ionos/poc/wordpress:latest

# Update deployment
kubectl set image deployment/wordpress wordpress=wp-openwebui.cr.de-fra.ionos.com/jubalm/ionos/poc/wordpress:latest -n wordpress-tenant1
```

### 4. Database Access
```bash
# PostgreSQL (Authentik)
psql -h pg-ng6akjkmbb4rn9e5.postgresql.de-txl.ionos.com -U authentik -d authentik

# MariaDB (WordPress)
mysql -h ma-d8nn61870q23eimk.mariadb.de-txl.ionos.com -u wordpress -p wordpress_tenant1
```

## Testing Procedures

### OAuth2 Flow Testing
```bash
# 1. Get authorization URL
curl -H "Host: authentik.local" http://85.215.220.121/application/o/authorize/?client_id=openwebui-client

# 2. Test token endpoint
curl -X POST -H "Host: authentik.local" http://85.215.220.121/application/o/token/ \
  -d "grant_type=authorization_code" \
  -d "code=<auth-code>" \
  -d "client_id=openwebui-client" \
  -d "client_secret=openwebui-secret-2025"
```

### API Testing
```bash
# WordPress API
curl -H "Host: wordpress-tenant1.local" http://85.215.220.121/wp-json/wp/v2/posts

# OpenWebUI API
curl -H "Host: openwebui.local" http://85.215.220.121/api/v1/models

# Pipeline Service
curl -H "Host: wordpress-tenant1.local" http://85.215.220.121:9099/health
```

## Troubleshooting

### Common Issues

#### Pod CrashLoopBackOff
```bash
# Check logs
kubectl logs -n <namespace> <pod-name> --previous

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

#### Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints -n <namespace>

# Check ingress
kubectl get ingress -A

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup <service-name>
```

#### Image Pull Errors
```bash
# Check secret
kubectl get secret ionos-cr-secret -n <namespace>

# Verify registry access
docker pull wp-openwebui.cr.de-fra.ionos.com/jubalm/ionos/poc/<image>
```

## Local Development

### Running Services Locally
```bash
# WordPress
cd docker/wordpress
docker-compose up

# OpenWebUI
cd docker/openwebui
docker run -p 3000:8080 ghcr.io/open-webui/open-webui:main

# Pipeline Service
cd pipelines
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python wordpress_oauth.py
```

### Environment Variables
Create `.env` files for local development:

```bash
# WordPress .env
WORDPRESS_DB_HOST=localhost
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=wordpress
WORDPRESS_DB_NAME=wordpress

# OpenWebUI .env
ENABLE_OAUTH_SIGNUP=true
OAUTH_CLIENT_ID=openwebui-client
OAUTH_CLIENT_SECRET=openwebui-secret-2025
```

## GitHub Actions

### Running Workflows
```bash
# Trigger deployment
gh workflow run deploy.yml

# Check status
gh run list --workflow=deploy.yml

# View logs
gh run view <run-id> --log
```

## Useful Aliases
Add to your `.bashrc` or `.zshrc`:

```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
alias kpf='kubectl port-forward'
```