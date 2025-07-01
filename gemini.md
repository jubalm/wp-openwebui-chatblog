# Gemini Project Context: IONOS MKS PoC (wp-openwebui)

This document provides context for the AI assistant about the project. It is based on the Product Requirements Document (`docs/product-requirements.md`).

## 1. Project Overview

This is a Proof of Concept (PoC) project to deploy and integrate a multi-tenant application stack on IONOS Managed Kubernetes (MKS). The stack consists of:
- A single **OpenWebUI** instance (a web UI for LLMs).
- A single **Authentik** instance (for SSO).
- Multiple isolated **WordPress** instances (one per tenant).

The project uses IONOS Managed Databases (PostgreSQL for Authentik, MariaDB for each WordPress tenant) and Terraform for infrastructure provisioning. A key feature is the **ModelContextProtocol (MCP)**, a custom integration enabling OpenWebUI to communicate with the WordPress instances to draft blog posts.

## 2. Core Technologies

- **Cloud Platform:** IONOS Cloud
  - IONOS Managed Kubernetes (MKS) in `de/txl`
  - IONOS Managed MariaDB & PostgreSQL
  - IONOS Object Storage (for Terraform state)
  - IONOS OpenAI-compatible LLM Endpoint
- **Infrastructure as Code:** Terraform (`/terraform`)
- **Container Orchestration:** Kubernetes
- **Applications:**
  - **Authentik:** SSO provider.
  - **WordPress:** Custom Docker image including the `wordpress-mcp` and OIDC plugins.
  - **OpenWebUI:** Web UI for LLMs.
- **CI/CD & Secrets:** GitHub Actions (`.github/workflows`), with a unified `plan -> approve -> apply` workflow.
- **Key Protocols:** OIDC (SSO), ModelContextProtocol (MCP), OpenAI API.

## 3. Architecture Summary

- **Infrastructure:** All IONOS cloud resources (MKS cluster, node pools, databases) are defined and managed by Terraform scripts located in the `/terraform` directory. The Terraform state is stored in IONOS Object Storage.
- **Kubernetes Layout:**
  - `admin-apps` namespace: Hosts the shared Authentik and OpenWebUI deployments.
  - `wordpress-tenant-<name>` namespaces: Each WordPress tenant is deployed in its own isolated namespace.
- **Application Integration:**
  - **Authentication:** Authentik acts as the central OIDC SSO provider for both OpenWebUI and all WordPress instances.
  - **Database:** Authentik uses a managed PostgreSQL instance. Each WordPress instance uses its own dedicated managed MariaDB instance.
  - **LLM & Content:** OpenWebUI connects to an IONOS-provided OpenAI-compatible LLM endpoint. It then uses the ModelContextProtocol (MCP) to send generated content as draft posts to the appropriate WordPress tenant.
- **Networking:**
  - Internal communication uses standard Kubernetes services and DNS (e.g., `openwebui` to `wordpress-mcp-service.wordpress-tenant-foo.svc.cluster.local`).
  - External access is provided via IP-based Kubernetes Ingress rules. No custom domains or TLS are in scope for this PoC.
- **Secrets Management:** Sensitive data (API tokens, database credentials) are managed securely. Per-tenant WordPress database passwords are now automatically generated using Terraform's `random` provider, ensuring unique and strong credentials for each tenant. Other secrets are stored as GitHub Actions secrets and injected into the cluster as Kubernetes Secrets during the CI/CD workflow.

## 4. Key Project Goals

- Provision the entire infrastructure using Terraform.
- Deploy and configure the full application stack (Authentik, OpenWebUI, multiple WordPress tenants) on MKS.
- Implement end-to-end SSO using Authentik.
- Demonstrate OpenWebUI interacting with the IONOS LLM.
- Demonstrate OpenWebUI creating draft posts in any WordPress tenant via the MCP integration.
- Automate deployment and secret management using GitHub Actions.
