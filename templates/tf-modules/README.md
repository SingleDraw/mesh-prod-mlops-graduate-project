# Terraform Modules Repository

This repository contains reusable Terraform modules shared across the AzureML + Databricks platform infrastructure.

The repository acts as the foundational infrastructure layer for the platform and is consumed by downstream live infrastructure repositories responsible for deploying actual environments and workloads.

Modules are intentionally isolated, composable, and environment-agnostic to support reuse across multiple projects and deployment stages.

---

# Repository Structure

```text id="3x1l5r"
modules/
├── acr/
├── auth/
├── directory-role-assignement/
├── github-secrets/
├── role-assignment/
├── storage-account/
└── test/
```

Each module follows a standardized Terraform layout:

```text id="0h9ynm"
module/
├── main.tf
├── variables.tf
├── outputs.tf
└── versions.tf
```

Some modules additionally include:

```text id="7d9m8p"
locals.tf
README.md
*.md
```

for internal documentation and implementation notes.

---

# Purpose

This repository exists to centralize infrastructure primitives and avoid duplication across:

* platform infrastructure
* workload infrastructure
* AzureML environments
* Databricks environments
* CI/CD infrastructure
* authentication and RBAC configuration

The modules are consumed primarily by the live Terraform repository generated from the control plane.

---

# Architecture Role

The overall infrastructure flow is structured as:

```text id="1n2e6k"
tf-modules
      ↓
tf-live
      ↓
Azure Infrastructure
      ↓
Databricks + AzureML Workloads
```

The `tf-live` repository composes these modules into actual deployable environments.

---

# Authentication

This repository is private.

Downstream Terraform repositories authenticate against it using Git deploy keys.

Deploy key generation and injection are automated by the control plane repository during repository bootstrap and CI/CD setup.

Consumers therefore do not need to manually configure authentication when generated through the platform orchestration flow.

Terraform module sources are typically referenced through Git URLs:

```hcl id="7y4v2b"
module "storage_account" {
  source = "git::ssh://git@github.com/org/tf-modules.git//modules/storage-account"

  ...
}
```

---

# Repository Consumption

This repository is not intended to be deployed directly.

It is designed to be consumed by:

```text id="f4n0pd"
templates/tf-live/
```

or by generated live infrastructure repositories derived from that template.

The repository should therefore be treated as a shared infrastructure dependency rather than a standalone deployment project.

---

# Terraform Standards

All modules are expected to:

* remain environment-agnostic
* avoid hardcoded values
* expose reusable outputs
* keep provider assumptions minimal
* support CI/CD execution
* support non-interactive deployments

The repository follows a composition-first model where infrastructure assembly happens at the live repository layer rather than inside modules themselves.

---

# Local Validation

A lightweight test module exists for isolated validation and development:

```text id="7myc8o"
modules/test/
```

This can be used for:

* syntax validation
* provider validation
* module iteration
* local experimentation

---

# Related Repositories

| Repository      | Purpose                                 |
| --------------- | --------------------------------------- |
| `tf-backend`    | Terraform remote state bootstrap        |
| `tf-live`       | Environment composition and deployments |
| `azureml`       | AzureML workloads and ML pipelines      |
| `databricks`    | Databricks workloads and data pipelines |
| `control-plane` | Repository generation and orchestration |

---

# Notes

This repository is part of a larger multi-repository platform architecture.

Most operational workflows such as:

* repository generation
* deploy key injection
* GitHub secret management
* CI/CD bootstrap
* Terraform backend configuration

are orchestrated externally by the control plane repository.
