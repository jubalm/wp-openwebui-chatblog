# Kubernetes PersistentVolumeClaim

Generate YAML for a PersistentVolumeClaim:
- Name: `{{pvc_name}}`
- Namespace: `{{namespace | default: "poc-apps"}}`
- Storage request: `{{storage_size | default: "5Gi"}}`
- Access mode: `{{access_mode | default: "ReadWriteOnce"}}`
- Storage class: Remind me to use the appropriate IONOS CSI storage class (e.g., `ionos-enterprise-hdd` or `ionos-enterprise-ssd`). Check current IONOS documentation for valid storage class names.
