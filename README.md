# IONOS WordPress & OpenWebUI PaaS

This project provides a fully automated, multi-tenant Platform-as-a-Service (PaaS) for hosting WordPress instances on IONOS Managed Kubernetes (MKS). It features seamless integration with a shared OpenWebUI for AI-powered content generation and Authentik for centralized Single Sign-On (SSO).

The entire platform is managed via Infrastructure as Code (IaC) using Terraform and automated with GitHub Actions.

## ✨ Features

- **Fully Automated Deployment:** Zero-touch deployment of the entire stack.
- **Multi-Tenant Architecture:** Securely isolated WordPress instances with dedicated databases.
- **Centralized Authentication:** SSO for all services provided by Authentik.
- **AI Content Generation:** Shared OpenWebUI service connected to the IONOS LLM endpoint for creating WordPress drafts.
- **Custom WordPress Environment:** Pre-configured Docker image with necessary plugins and automated installation.
- **Dynamic Secrets Management:** Secure, automated pipeline for managing credentials.

## 🚀 Getting Started

Deployment is fully automated via GitHub Actions.

### Prerequisites

1.  **IONOS Account:** An active IONOS account.
2.  **IONOS Token:** An authentication token with permissions to create MKS clusters, databases, and S3 buckets.
3.  **GitHub Repository:** A fork of this repository.
4.  **GitHub Actions Secrets:** Configure the following secrets in your repository settings:
    - `IONOS_TOKEN`: Your IONOS API token.
    - `IONOS_S3_KEY`: Your IONOS S3 access key.
    - `IONOS_S3_SECRET`: Your IONOS S3 secret key.

### Installation Steps

1.  **Build the Custom WordPress Image:**
    - Go to the **Actions** tab in your GitHub repository.
    - Run the **Build and Push WordPress Image** workflow. This builds the image from `docker/wordpress` and pushes it to your container registry.
    > **Note:** You may need to update the image location in `charts/wordpress/values.yaml` to point to your registry.

2.  **Deploy the Platform:**
    - In the **Actions** tab, run the **Deploy Infrastructure & Applications** workflow.
    - Provide a **tenant name** when prompted (e.g., `acme-corp`).
    - The workflow will provision all cloud resources and deploy the applications.

## ��� Architecture & Documentation

A detailed technical overview of the architecture, including the Terraform structure, Kubernetes layout, and CI/CD pipelines, can be found in the [**TECHNICAL_OVERVIEW.md**](./TECHNICAL_OVERVIEW.md) document.
