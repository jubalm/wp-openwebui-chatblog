✦ The workflow failed again. The 2. Plan Platform job failed at the Terraform
  Plan step.


  I'll check the logs of the failed run to understand what went wrong. I'll
  use gh run view to get the details of the failed job.

...

I've found the errors in the logs. The plan-platform job failed during
  terraform plan with two errors:


   1. Unsupported Argument: Error: Unsupported argument. An argument named
      "kubeconfig" is not expected here. This is for the kubernetes
      provider.
   2. Reference to Undeclared Resource: Error: Reference to undeclared
      resource. A data resource "ionoscloud_k8s_cluster" "mks" has not been
      declared in the root module. This is for the kubeconfig output.


  I made a mistake in the platform/main.tf file. The kubernetes provider
  doesn't accept a kubeconfig argument directly. It should be config_path or
  other configuration. Also, I'm trying to output a kubeconfig that is no
  longer defined in this module.

  I'll fix this by:


   1. Removing the kubeconfig output from platform/main.tf.
   2. Correcting the kubernetes and helm provider configurations in
      platform/main.tf. I'll use the KUBE_CONFIG_PATH environment variable,
      which is the standard way to point to a kubeconfig file. 