# IONOS MKS PoC: Architecture Overview

## High-Level Architecture

This document describes the architecture for the IONOS MKS Proof of Concept (PoC), which demonstrates multi-tenant WordPress, OpenWebUI, and Authentik SSO integration, all provisioned and managed via Terraform and deployed on IONOS Cloud.

### Key Components

- **IONOS Managed Kubernetes (MKS):** Hosts all application workloads.
- **IONOS Managed Databases:**
  - **MariaDB:** One per WordPress tenant.
  - **PostgreSQL:** For Authentik.
- **IONOS Object Storage (S3):** Stores Terraform state.
- **IONOS OpenAI-compatible LLM Endpoint:** Used by OpenWebUI.
- **GitHub Actions:** CI/CD, secrets management, and automation.
- **Kubernetes Namespaces:**
  - `admin-apps`: Authentik, OpenWebUI
  - `tenant-<name>`: One per WordPress tenant
- **Ingress:** IP-based access to all UIs (no custom domains/TLS).
- **Secrets:** Managed via GitHub Actions and Kubernetes Secrets.

### Application Integrations

- **Authentik:** SSO provider (OIDC) for both OpenWebUI and all WordPress tenants. Uses PostgreSQL and Redis.
- **OpenWebUI:** LLM UI, OIDC client to Authentik, connects to LLM endpoint, and communicates with WordPress tenants via MCP.
- **WordPress (per tenant):** OIDC client to Authentik, includes MCP and custom integration plugins, connects to its own MariaDB.

---

## Architecture Diagram

```mermaid
flowchart TD
  subgraph Cloud["IONOS Cloud (de/txl)"]
    direction TB
    S3["IONOS Object Storage (S3)\n(Terraform State)"]
    subgraph DBs["Managed Databases"]
      MariaDB1["MariaDB (Tenant 1)"]
      MariaDB2["MariaDB (Tenant 2..N)"]
      PG["PostgreSQL (Authentik)"]
    end
    subgraph K8s["Managed Kubernetes (MKS)"]
      subgraph Admin["Namespace: admin-apps"]
        Authentik["Authentik\n(SSO, OIDC, Redis)"]
        OpenWebUI["OpenWebUI\n(LLM UI, OIDC Client)"]
      end
      subgraph WP["Namespaces: wordpress-tenant-<name>"]
        WP1["WordPress (Tenant 1)\n+ MCP Plugin\n+ OIDC Plugin"]
        WP2["WordPress (Tenant 2..N)\n+ MCP Plugin\n+ OIDC Plugin"]
      end
    end
    LLM["IONOS OpenAI-compatible LLM Endpoint"]
  end

  %% Networking and Integrations
  OpenWebUI -- "OIDC SSO" --> Authentik
  WP1 -- "OIDC SSO" --> Authentik
  WP2 -- "OIDC SSO" --> Authentik
  Authentik -- "DB Conn" --> PG
  Authentik -- "Redis" --> Authentik
  WP1 -- "DB Conn" --> MariaDB1
  WP2 -- "DB Conn" --> MariaDB2
  OpenWebUI -- "OpenAI API" --> LLM
  OpenWebUI -- "MCP (Draft Blog Post)" --> WP1
  OpenWebUI -- "MCP (Draft Blog Post)" --> WP2
  S3 -.-> K8s
  S3 -.-> DBs

  %% Ingress
  Ingress["K8s Ingress (IP-based)"]
  Ingress --> Authentik
  Ingress --> OpenWebUI
  Ingress --> WP1
  Ingress --> WP2

  %% CI/CD
  GHA["GitHub Actions\n(CI/CD, Secrets)"]
  GHA -- "Terraform, Secrets" --> S3
  GHA -- "Terraform, Secrets" --> K8s
  GHA -- "Terraform, Secrets" --> DBs

  %% User Flows
  User["User/Tester"]
  User -- "SSO Login" --> Authentik
  User -- "Login, Blog, Chat" --> WP1
  User -- "Login, Blog, Chat" --> WP2
  User -- "Login, Content Gen" --> OpenWebUI

  %% Legend
  classDef infra fill:#222,stroke:#333,stroke-width:2px,color:#222;
  classDef app fill:#cce6ff,stroke:#333,stroke-width:2px,color:#222;
  classDef db fill:#d6f5d6,stroke:#333,stroke-width:2px,color:#222;
  classDef ext fill:#fff9c4,stroke:#333,stroke-width:2px,color:#222;
  class S3,LLM,GHA,User ext;
  class K8s,DBs infra;
  class Authentik,OpenWebUI,WP1,WP2 app;
  class MariaDB1,MariaDB2,PG db;
```

---

## Summary

- **Multi-tenancy:** Each WordPress tenant is isolated (namespace, DB, plugins), but shares Authentik and OpenWebUI.
- **SSO:** Authentik provides OIDC SSO for all apps.
- **Content Generation:** OpenWebUI uses the IONOS LLM and can send drafts to any tenant's WordPress via MCP.
- **Automation:** All infra and secrets are managed via Terraform and GitHub Actions.
- **Ingress:** All UIs are accessible via IP-based ingress (no custom domains/TLS for PoC).
