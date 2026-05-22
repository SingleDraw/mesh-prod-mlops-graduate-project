# Terraform Live Infrastructure Repository

This repository defines the actual deployable infrastructure for the platform. It composes reusable Terraform modules into real environments and is responsible for provisioning and maintaining all Azure-based infrastructure for both platform and workload layers.

It sits one level above the module library and acts as the point where abstract infrastructure components become concrete environments.

---

# Repository Role in the Platform

The infrastructure flow is intentionally split:

```text
tf-modules → tf-live → Azure Infrastructure → Databricks + AzureML Workloads
```

`tf-live` is the composition layer. It does not implement infrastructure primitives. Instead, it assembles them into coherent environments such as platform foundations and workload-specific deployments.

---

# Repository Structure

```text
platform/
├── backend.tf
├── main.tf
├── outputs.tf
└── variables.tf

workloads/
├── azure-ml/
│   ├── backend.tf
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
└── databricks/
    ├── backend.tf
    ├── main.tf
    ├── providers.tf
    ├── variables.tf
    └── versions.tf
```

The repository is intentionally split into two logical domains:

* **platform/** defines shared foundational infrastructure
* **workloads/** defines environment-specific infrastructure for compute and data systems

---

# Design Philosophy

The repository follows a strict composition model:

Infrastructure is not duplicated here. It is assembled.

All actual resources are sourced from the private `tf-modules` repository using Git-based module sources. Authentication is handled through deploy keys automatically injected by the control plane during repository bootstrap and CI/CD configuration.

This means `tf-live` remains clean of secret management concerns and focuses purely on environment definition.

---

# Execution Model

Infrastructure is applied per domain rather than as a single monolithic state.

The typical lifecycle is:

```text
platform apply → shared infrastructure exists
        ↓
workload apply → AzureML / Databricks environments
        ↓
CI/CD pipelines → continuous updates
```

Each subdirectory is independently deployable and has its own state, backend configuration, and provider setup.

---

# Backend Strategy

Terraform state is isolated per environment. Each subdomain manages its own backend configuration to avoid coupling between platform and workloads.

State separation ensures:

* independent lifecycle management
* safer workload iteration
* controlled blast radius during changes
* parallel development of platform and ML systems

---

# Module Consumption

All infrastructure components are sourced from the private `tf-modules` repository using SSH-based Git module references.

The authentication layer is not managed manually here. It is injected automatically by the control plane during repository generation and CI/CD bootstrap.

This repository assumes a fully provisioned identity and credential setup before any Terraform execution.

---

# CI/CD Integration

Infrastructure changes are designed to be executed through GitHub Actions workflows defined in the generated environment.

Typical automation includes:

* validation of Terraform plans
* environment-specific applies
* controlled workload deployment
* safe destroy workflows for ephemeral environments

The repository is not intended for manual Terraform execution in production workflows.

---

# Environment Separation

Workloads are intentionally isolated:

* `platform/` manages shared infrastructure dependencies
* `workloads/azure-ml/` manages ML training and deployment infrastructure
* `workloads/databricks/` manages data engineering and pipeline infrastructure

This separation allows independent scaling and iteration of each system without cross-impact.

---

# Operational Flow

A typical deployment lifecycle looks like:

```text
control plane generates repo
        ↓
deploy keys injected automatically
        ↓
platform infrastructure provisioned
        ↓
workload infrastructure deployed
        ↓
CI/CD pipelines maintain state and updates
```

`tf-live` is the execution layer of this workflow.

---

# Notes on Design Constraints

This repository is intentionally minimal in abstraction. It avoids:

* defining reusable primitives (handled in tf-modules)
* managing secrets directly (handled by control plane automation)
* embedding application logic (handled by Databricks / AzureML repos)

Its only responsibility is deterministic infrastructure composition.

---

# Related Repositories

| Repository      | Role                                    |
| --------------- | --------------------------------------- |
| `tf-modules`    | Infrastructure building blocks          |
| `control-plane` | Repository generation and orchestration |
| `databricks`    | Data engineering workloads              |
| `azureml`       | ML training and deployment workflows    |

---

This repository represents the final assembly stage before infrastructure is materialized in Azure.
