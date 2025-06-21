# Terraform for New IONOS MKS Node Pool

Help me add a new node pool to our existing IONOS MKS cluster (referenced via `ionoscloud_k8s_cluster.main_mks_cluster.id` or similar variable).
- Node pool name: `{{nodepool_name}}`
- Datacenter ID/Location: Should match the main cluster's datacenter.
- Node count: `{{node_count}}` (e.g., 2)
- Instance type/size: `{{instance_type}}` (e.g., `CUBE_S_AMD` or a suitable IONOS SKU for `{{workload_type}}`)
- Kubernetes version should match the cluster's version (or be compatible).
- Add standard labels like `workload-type: {{workload_type_label}}`.
