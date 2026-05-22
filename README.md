# Control Plane for AzureML + Databricks MLOps Platform

This repository provides the control plane and project scaffolding for an end-to-end MLOps platform built around:

* Microsoft Azure infrastructure provisioning with Terraform
* Databricks medallion-style data engineering pipelines
* Azure Machine Learning training, evaluation, model registration, and deployment workflows
* GitHub Actions driven CI/CD orchestration
* Local-first notebook development with later productionalization into cloud runtimes

The repository acts as a centralized orchestration layer responsible for:

* generating live repositories from templates
* bootstrapping infrastructure
* wiring authentication and GitHub secrets
* deploying workloads
* managing reusable Terraform modules
* standardizing project structure across environments

The system is designed around repository templating and infrastructure automation rather than storing only a single ML project. It provides reusable foundations for spinning up complete AzureML + Databricks environments consistently.

---

# Architecture Overview

The repository separates responsibilities into distinct layers:

| Layer                  | Purpose                                                |
| ---------------------- | ------------------------------------------------------ |
| `templates/`           | Source templates for generated live repositories       |
| `make/`                | Orchestration layer implemented with modular Makefiles |
| `scripts/`             | Operational scripts used by CI/CD and local automation |
| `docker/`              | Local runtime environments for development             |
| `templates/tf-modules` | Reusable Terraform modules                             |
| `templates/tf-backend` | Terraform remote state bootstrap                       |
| `templates/tf-live`    | Live infrastructure repository template                |
| `templates/databricks` | Databricks engineering repository template             |
| `templates/azureml`    | AzureML training and deployment repository template    |

The overall workflow looks like this:

```text
Control Plane Repo
        │
        ├── Generates Live Repositories
        │       ├── tf-modules
        │       ├── tf-backend
        │       ├── tf-live
        │       ├── databricks
        │       └── azureml
        │
        ├── Bootstraps Infrastructure
        │       └── Terraform + Azure
        │
        ├── Configures CI/CD
        │       └── GitHub Actions + Secrets + Credentials
        │
        ├── Deploys Data Platform
        │       └── Databricks Medallion Pipelines
        │
        └── Deploys ML Platform
                └── AzureML Pipelines + Endpoints
```

---

# Repository Structure

## `make/`

Contains the orchestration layer for the entire platform.

The root `Makefile` aggregates modular Makefiles organized by domain:

```text
make/
├── AzureML/
├── Databricks/
├── Terraform/
├── Local/
├── Config.mk
└── Utils.mk
```

This layer exposes high-level commands such as:

```bash
make generate-live-repo
make trigger-live-platform-ci
make generate-databricks-repo
make generate-azureml-repo
```

The Makefiles internally coordinate shell scripts, repository generation, credential injection, deployment workflows, and infrastructure provisioning.

---

## `templates/`

Contains self-contained repository templates used to generate actual working repositories.

Generated repositories are intended to become independent Git repositories.

### Terraform Templates

| Template     | Purpose                               |
| ------------ | ------------------------------------- |
| `tf-backend` | Bootstraps Terraform remote state     |
| `tf-live`    | Production infrastructure definitions |
| `tf-modules` | Reusable infrastructure modules       |

Infrastructure includes components such as:

* Azure Resource Groups
* Storage Accounts
* AzureML Workspaces
* Authentication resources
* Role assignments
* GitHub secret automation
* AKS and supporting infrastructure

---

### Databricks Template

Implements medallion-style data engineering pipelines.

```text
Bronze → Silver → Gold
```

The workflow intentionally separates experimentation from production engineering.

Local notebooks use Pandas for rapid iteration and debugging, while production code is later migrated into PySpark-based implementations for Databricks runtime execution.

Structure highlights:

```text
templates/databricks/
├── notebooks/local_dev/
├── src/bronze/
├── src/silver/
├── src/gold/
└── resources/jobs/
```

The repository also contains GitHub workflows for deployment automation and dataset uploads.

---

### AzureML Template

Implements reusable ML training and deployment workflows.

Includes:

* reusable pipeline components
* AzureML environments
* datastores
* datasets
* MLTable definitions
* model registration workflows
* endpoint deployment automation

Structure highlights:

```text
templates/azureml/
├── ml/components/
├── ml/pipelines/
├── ml/environments/
├── notebooks/local_dev/
└── .github/workflows/
```

The AzureML repository focuses primarily on:

* feature consumption
* model training
* evaluation
* experiment tracking
* deployment orchestration

---

# Development Model

The platform follows a staged development flow.

## Data Engineering Phase

Work begins locally using notebooks and lightweight datasets:

```text
Local Notebook Development
        ↓
Feature Engineering
        ↓
Validation & Cleaning
        ↓
Migration to PySpark
        ↓
Databricks Production Pipelines
```

This enables fast experimentation before committing logic into distributed processing pipelines.

---

## Machine Learning Phase

AzureML workflows consume curated datasets and features produced by Databricks pipelines.

The flow typically becomes:

```text
Databricks Gold Dataset
        ↓
AzureML Dataset Registration
        ↓
Training Pipeline
        ↓
Evaluation
        ↓
Model Registration
        ↓
Endpoint Deployment
```

---

# Prerequisites

The following tooling is expected:

* Terraform
* Docker
* Azure CLI
* GitHub CLI
* Git
* WSL or Linux environment
* Python 3.x
* Conda or virtualenv

You also need:

* Azure subscription with sufficient permissions
* GitHub access for CI/CD workflows

---

# Getting Started

## 1. Clone Repository

```bash
git clone <repo-url>
cd <repo>
```

---

## 2. Configure Environment

Create a local environment file:

```bash
cp .env.example .env
```

Fill in all required values.

Important:

`LOCAL_REPOS` must point outside this repository.

Generated repositories initialize their own Git repositories internally, so nesting them inside this repository will cause Git conflicts.

Correct example:

```text
/workspace
├── control-plane
├── live-databricks
├── live-azureml
└── tf-live
```

Incorrect example:

```text
control-plane/
└── generated-repos/
```

---

# Bootstrap Flow

Infrastructure provisioning should be performed in the following order.

## Terraform Platform Bootstrap

```bash
make generate-modules-repo
make generate-bootstrap
make generate-live-repo

make trigger-live-platform-ci
make trigger-live-workload-dbx-ci
make trigger-live-workload-azureml-ci
```

This stage:

* creates Terraform repositories
* provisions remote state
* deploys shared infrastructure
* deploys workload infrastructure

---

## Databricks Deployment

```bash
make generate-databricks-repo

make trigger-upload-xlsx-workflow
make trigger-dbx-cd-workflow
```

This stage:

* generates the Databricks repository
* uploads source datasets
* deploys Databricks jobs and pipelines

---

## AzureML Deployment

```bash
make store-datalake-client-creds-azureml

make generate-azureml-repo

make trigger-azureml-workflow-upload-mltable
make trigger-azureml-workflow-datalake-registration
make trigger-azureml-workflow-delta-resource-registration
make trigger-azureml-workflow-submit-delta-pipeline
```

This stage:

* generates the AzureML repository
* registers datasets and datastores
* uploads MLTable definitions
* deploys AzureML resources
* executes training pipelines

---

# Idempotency Notes

Repository generation commands are designed to be reproducible.

However:

* generated repositories are fully overwritten during regeneration
* force pushes may occur
* uncommitted changes can be lost

Always commit work inside generated repositories before re-running generation commands.

---

# Local Development

A local JupyterLab runtime is included:

```text
docker/
├── Dockerfile.jupyterlab
└── jupyter.yml
```

This environment is intended for:

* notebook experimentation
* feature engineering
* local validation
* testing utility modules

---

# CI/CD

The platform heavily relies on GitHub Actions.

Workflows are included directly inside repository templates and cover:

* Terraform deployment
* dataset uploads
* pipeline execution
* model registration
* endpoint deployment
* infrastructure destruction workflows

---

# Repository Philosophy

This repository is intentionally structured as an orchestration platform rather than a single deployable application.

The goal is to standardize:

* infrastructure provisioning
* repository structure
* CI/CD pipelines
* ML workflows
* data engineering patterns
* authentication setup
* operational tooling

across multiple AzureML and Databricks projects with minimal manual setup.
