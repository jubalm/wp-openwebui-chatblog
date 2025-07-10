# Manual Nuclear Cleanup Commands

## Context
The automated cleanup in the GitHub Actions workflow is not removing all authentik resources completely. This manual cleanup will obliterate every trace of authentik to allow fresh deployment.

## Commands to Run

```bash
# Step 1: Setup kubeconfig
kubectl config use-context cluster-admin@mks-cluster

# Step 2: Remove helm releases
helm uninstall authentik -n admin-apps --ignore-not-found
helm uninstall authentik-new -n admin-apps --ignore-not-found

# Step 3: Nuclear resource deletion
kubectl delete all,secrets,cm,sa,pvc,ingress -n admin-apps -l app.kubernetes.io/name=authentik --ignore-not-found
kubectl delete all,secrets,cm,sa,pvc,ingress -n admin-apps -l app=authentik --ignore-not-found
kubectl delete secret authentik-env-secrets -n admin-apps --ignore-not-found
kubectl delete secret authentik -n admin-apps --ignore-not-found
kubectl delete sa authentik authentik-new authentik-new-redis -n admin-apps --ignore-not-found
kubectl delete pvc redis-data-authentik-new-redis-master-0 redis-data-authentik-redis-master-0 -n admin-apps --ignore-not-found

# Step 4: Clean terraform state
cd terraform/platform
export AWS_ACCESS_KEY_ID="EAAAAAXj2lN67wFMnqEad-Lk5L7-8eBhU98YUey6k-vZ9bpp1QAAAAEB5scTAAAAAAHmxxOYWNnzti7BXQtEIMEg1wtP"
export AWS_SECRET_ACCESS_KEY="3hisuK2qUVtdP1XtQftsTYq8Zc9ia7mJmxUcpWD26F3vbEpxEadSQMeztifbqgw2"
terraform state rm helm_release.authentik
terraform state rm kubernetes_secret.authentik_env

# Step 5: Verify cleanup
kubectl get all,secrets,cm,sa,pvc -n admin-apps | grep -i authentik || echo "All clean!"
```

## After Manual Cleanup

Run the GitHub Actions workflow again. It should now deploy successfully without any "already exists" errors.

## Expected Result

Perfect one-shot deployment from Infrastructure → Platform → Tenants → Post-Deploy without any conflicts.
