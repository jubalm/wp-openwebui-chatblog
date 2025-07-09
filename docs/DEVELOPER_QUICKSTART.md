# Developer Quickstart Guide

> **Last Updated**: July 8, 2025  
> **Purpose**: Essential commands and procedures for developers

## Prerequisites
- IONOS CLI (`ionosctl`) installed
- `kubectl` installed
- `k9s` installed (highly recommended for cluster monitoring)
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

### 2. Install k9s (Recommended)
k9s provides a powerful terminal-based UI for managing Kubernetes clusters.

#### Installation
```bash
# macOS (via Homebrew)
brew install k9s

# Linux (via Snap)
sudo snap install k9s

# Windows (via Scoop)
scoop install k9s

# Or download binary from GitHub releases
# https://github.com/derailed/k9s/releases
```

#### Launch k9s
```bash
# Start k9s with your kubeconfig
export KUBECONFIG=./kubeconfig.yaml
k9s
```

## Monitoring with k9s

### k9s Navigation Basics
- `:pods` - View all pods
- `:svc` - View services
- `:ing` - View ingresses
- `:ns` - View namespaces
- `:no` - View nodes
- `/` - Filter resources
- `Enter` - Describe resource
- `l` - View logs
- `s` - Shell into pod
- `?` - Help menu

### Platform-Specific Monitoring

#### Monitor Platform Services
```bash
# In k9s, navigate to admin-apps namespace
:ns
# Select admin-apps and press Enter
# Then view pods
:pods
```

Key services to monitor in `admin-apps`:
- `authentik-server` - SSO authentication
- `authentik-worker` - Background tasks
- `open-webui` - AI chat interface
- `wordpress-oauth-pipeline` - Content automation

#### Monitor WordPress Tenants
```bash
# Filter namespaces containing "wordpress"
:ns
/wordpress
```

For each tenant namespace:
- `wordpress-{tenant}` - WordPress instance
- `mariadb-{tenant}` - Database (if deployed in cluster)

#### Quick Health Checks in k9s
1. **Press `:pods`** - Check for any pods not in "Running" state
2. **Press `:svc`** - Verify services have endpoints
3. **Press `:ing`** - Check ingress rules and LoadBalancer status
4. **Press `:events`** - View recent cluster events

#### Useful k9s Shortcuts for This Platform
- `:pods -n admin-apps` - Direct to admin-apps pods
- `:logs -n admin-apps authentik-server` - View Authentik logs
- `:describe pod/open-webui` - Get pod details
- `:top pods` - View resource usage

### k9s Quick Reference for WordPress-OpenWebUI Platform

#### Essential Views
| Command | Description |
|---------|-------------|
| `:pods` | View all pods across namespaces |
| `:pods -n admin-apps` | Focus on platform services |
| `:svc` | Check service endpoints |
| `:ing` | Monitor ingress rules |
| `:events` | Recent cluster events |
| `:ns` | Switch between namespaces |

#### Key Actions
| Key | Action |
|-----|--------|
| `Enter` | Describe selected resource |
| `l` | View logs (live tail) |
| `s` | Shell into pod |
| `d` | Delete resource |
| `y` | View YAML |
| `e` | Edit resource |
| `/` | Filter resources |
| `?` | Show help |

#### Platform Monitoring Workflow
1. Start: `k9s`
2. Check overall health: `:pods`
3. Monitor platform: `:pods -n admin-apps`
4. Check specific tenant: `:ns` → select tenant → `:pods`
5. View logs: select pod → `l`
6. Check connectivity: `:svc` → `:ing`

### 3. Essential Commands

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

### k9s-Based Troubleshooting (Recommended)

#### Pod Issues
1. **Press `:pods`** in k9s
2. **Look for pods** not in "Running/Completed" state
3. **Press `l`** on problematic pod to view logs
4. **Press `d`** to describe pod and see events
5. **Press `s`** to shell into running pod if needed

#### Service Connectivity Issues
1. **Press `:svc`** to view services
2. **Press `Enter`** on service to see endpoints
3. **Press `:ing`** to check ingress configuration
4. **Press `:events`** to see recent cluster events

#### Quick Debugging Workflow in k9s
```bash
# 1. Start k9s
k9s

# 2. Check overall cluster health
:pods
# Look for any non-Running pods

# 3. Check specific namespace
:ns
# Navigate to problematic namespace

# 4. Investigate pod logs
:pods
# Select pod, press 'l' for logs

# 5. Check events
:events
# Sort by timestamp to see recent issues
```

### Traditional CLI Troubleshooting

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

### Platform-Specific Troubleshooting

#### WordPress Tenant Issues
**Using k9s:**
1. `:ns` → filter by tenant name
2. `:pods` → check WordPress pod status
3. `l` → view WordPress logs
4. `:svc` → verify service endpoints

#### Authentik SSO Issues
**Using k9s:**
1. `:pods -n admin-apps`
2. Check `authentik-server` and `authentik-worker` status
3. `l` on authentik-server for authentication logs
4. `:ing` to verify ingress configuration

#### Content Pipeline Issues
**Using k9s:**
1. `:pods -n admin-apps`
2. Find `wordpress-oauth-pipeline` pod
3. `l` for pipeline logs
4. `s` to shell in and test Python imports

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
# Kubernetes CLI shortcuts
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
alias kpf='kubectl port-forward'

# k9s with kubeconfig
alias k9s='KUBECONFIG=./kubeconfig.yaml k9s'

# Quick access to platform namespaces
alias k9s-admin='k9s -n admin-apps'
alias k9s-tenant='k9s --all-namespaces | grep wordpress'
```

## Management Scripts

### Tenant Management
Use the tenant management script for multi-tenant operations:
```bash
# List all tenants
./scripts/tenant-management.sh list

# Create a new tenant
./scripts/tenant-management.sh create demo-company 'Demo Company' admin@demo.com pro

# Scale a tenant
./scripts/tenant-management.sh scale demo-company enterprise

# Test tenant health
./scripts/tenant-management.sh test demo-company
```

### Testing Scripts
Run comprehensive tests with the test scripts:
```bash
# Full integration test
./tests/scripts/test-integration.sh

# SSO validation
./tests/scripts/test-sso-integration.sh

# Content automation test
./tests/scripts/test-content-automation.sh

# Interactive demo
./tests/scripts/demo-tenant-system.sh
```

See [Scripts Documentation](../scripts/README.md) for complete details.