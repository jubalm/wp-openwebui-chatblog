I encountered this error on workflow run named "Plan Tenants" > "Terraform Plan"

│ Error: Unsupported argument
│ 
│   on main.tf line 42, in provider "kubernetes":
│   42:   kubeconfig = data.terraform_remote_state.infra.outputs.kubeconfig
│ 
│ An argument named "kubeconfig" is not expected here.
╵
╷
│ Error: Unsupported block type
│ 
│   on main.tf line 46, in provider "helm":
│   46:   kubernetes {
│ 
│ Blocks of type "kubernetes" are not expected here. Did you mean to define
│ argument "kubernetes"? If so, use the equals sign to assign it a value.
╵
Error: Terraform exited with code 1.
Error: Process completed with exit code 1.

i don't know which file it refers to but i may need more than just apply code changes. i would also need you to be actively debugging and helping me analyze the deployment issues i am facing; means running commands and pro-actively suggesting ways to better the code