https://github.com/hashicorp/terraform-mcp-server

# Tooling Overview

## Advanced Tooling

### Terraform MCP Server

The Terraform MCP Server is a [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) server that integrates seamlessly with Terraform Registry APIs, enabling advanced automation and interaction capabilities for Infrastructure as Code (IaC) development. Key features include:

- **Automating Provider and Module Discovery:** Simplifies the process of finding and using Terraform providers and modules.
- **Data Extraction and Analysis:** Extracts detailed information from the Terraform Registry, including provider resources, data sources, and modules.
- **Dynamic Recommendations:** Generates outputs and recommendations dynamically based on queries, models, and the connected MCP server.
- **Extensibility:** Supports advanced toolsets for querying provider documentation, searching modules, and retrieving module details.

### Installation and Usage

- **Docker Image:**
  - Clone the repository: `git clone https://github.com/hashicorp/terraform-mcp-server.git`
  - Build the Docker image: `make docker-build`
  - Run the server: `docker run -i --rm terraform-mcp-server`

- **VS Code Integration:**
  Add the following configuration to your User Settings (JSON):
  ```json
  {
    "mcp": {
      "servers": {
        "terraform": {
          "command": "docker",
          "args": [
            "run",
            "-i",
            "--rm",
            "hashicorp/terraform-mcp-server"
          ]
        }
      }
    }
  }
  ```

For more details, visit the [Terraform MCP Server GitHub Repository](https://github.com/hashicorp/terraform-mcp-server).

### Kubernetes CLI

Kubernetes CLI (`kubectl`) is essential for managing Kubernetes clusters. Key commands include:

- `kubectl get pods`: List all pods in the cluster.
- `kubectl apply -f <file>`: Apply a manifest file.
- `kubectl logs <pod>`: View logs of a specific pod.
- `kubectl exec -it <pod> -- <command>`: Execute a command inside a pod.

### Helm CLI

Helm CLI is used for managing Kubernetes applications via charts. Key commands include:

- `helm repo add <repo>`: Add a Helm repository.
- `helm install <name> <chart>`: Install a chart.
- `helm upgrade <name> <chart>`: Upgrade an existing release.
- `helm uninstall <name>`: Remove a release.

### Docker CLI

Docker CLI is used for building and managing container images. Key commands include:

- `docker build -t <image>`: Build a Docker image.
- `docker run <image>`: Run a container from an image.
- `docker ps`: List running containers.
- `docker stop <container>`: Stop a running container.
- `docker push <image>`: Push an image to a registry.

## Basic Tooling

- **Git:** Version control for tracking changes.
- **VS Code:** IDE for development.
- **cURL:** Command-line tool for API requests.
