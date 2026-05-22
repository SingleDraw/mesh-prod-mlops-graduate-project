# Azure Machine Learning Repository

This repository contains the machine learning layer of the platform built on Azure Machine Learning. It defines a complete end-to-end ML workflow from data ingestion to model evaluation, with a strict notebook-first development model and a single production pipeline boundary.

It is generated from the control plane and executed as an independent Git repository with full CI/CD orchestration.

---

# Role in the Platform

The repository is the final stage of the data-to-model system:

```text id="flow"
Databricks Gold Layer → MLTable → AzureML Pipeline → Model Evaluation
```

It consumes curated features from Databricks and produces a trained and evaluated regression model artifact.

There is no deployment or serving layer in this repository by design.

---

# Core Design Philosophy

The entire machine learning lifecycle is developed in notebooks first.

Notebooks are not exploratory-only artifacts — they are the primary execution environment where the full ML system is built, tested, and validated before being formalized into a production pipeline.

This ensures the production pipeline is always a deterministic reflection of a validated notebook workflow.

---

# ML Scope

The repository implements a single controlled machine learning pipeline:

```text id="ml-scope"
Prepare Data → Train Model → Evaluate Model
```

The model is based on:

* regression problem formulation
* sklearn pipeline
* ElasticNet regularized regression
* custom feature engineering steps

The scope is intentionally fixed to ensure reproducibility and predictable operational behavior.

---

# Repository Structure

```text id="structure"
notebooks/
├── local_dev/
└── utils/

ml/
├── components/
│   ├── prep/
│   ├── train/
│   └── eval/
├── data/
├── datastores/
├── environments/
└── pipelines/

config.yml
.github/
└── workflows/
```

The structure separates:

* notebook-driven development
* reusable pipeline components
* production pipeline definition
* CI/CD orchestration and versioning

---

# Notebook-Centric Development Model

The heart of this repository is the notebook layer.

All machine learning logic is developed locally inside notebooks:

```text id="notebook"
EDA → Feature Engineering → Local Model Training → Validation → Pipeline Refactor
```

Once stable, logic is refactored into AzureML pipeline components.

This guarantees:

* fast iteration during research
* reproducibility in production pipelines
* direct traceability between experimentation and deployment logic

---

# Data Flow

The ML pipeline consumes data from the Databricks Gold layer via MLTable definitions.

```text id="data-flow"
Databricks Gold Delta Table → MLTable → AzureML Pipeline
```

This creates a strict contract between data engineering and machine learning layers, ensuring consistent feature definitions across training runs.

---

# Pipeline Structure

The production pipeline is defined under:

```text id="pipeline"
ml/pipelines/
```

It consists of three sequential stages:

1. Data preparation using MLTable input
2. Model training using sklearn + ElasticNet + custom feature steps
3. Model evaluation and metric logging

The pipeline is the only production execution artifact in the system.

---

# Component Architecture

Notebook logic is refactored into reusable AzureML components:

```text id="components"
prep → train → eval
```

Each component represents a deterministic stage of the pipeline graph and is version-controlled independently.

---

# Configuration-Driven Versioning

A central part of this repository is the `config.yml` file.

It acts as the single source of truth for versioned ML resources:

```yaml id="config"
# Resource versions (to bump up manually)
versions:
  delta_env: "1.2.7"
  component_prepare: "1.2.7"
  component_train: "1.2.7"
  component_eval: "1.2.7"
  feature_store_gold_dataset: "1.2.7"
  delta_pipeline: "1.2.7"

delta:
  snapshot_time: "2024-11-01T00:00:00Z"

compute:
  instance_type: "standard_ds2_v2"
```

This file is explicitly **manually versioned**.

There is no automatic bumping mechanism.

Every change to ML resources must be reflected here before deployment.

---

# Versioning Semantics

The `config.yml` controls all CI/CD behavior in GitHub Actions workflows:

* component versions
* environment versions
* dataset versioning
* pipeline versioning
* compute configuration

Workflows read this file during execution and inject the correct versions into AzureML resources at deployment time.

This ensures:

* deterministic deployments
* explicit change tracking
* reproducible ML environments
* controlled promotion of resources

---

# Execution Model

All ML execution is orchestrated via GitHub Actions.

```text id="exec"
Control Plane
      ↓
Generate Repository
      ↓
Inject Credentials
      ↓
Read config.yml versions
      ↓
Register MLTable + Components
      ↓
Deploy Pipeline
      ↓
Run Training
      ↓
Evaluate Model
```

---

# CI/CD Behavior

Workflows manage:

* AzureML resource registration
* component deployment
* MLTable synchronization
* pipeline execution
* model evaluation runs

All deployments are version-aware and driven by `config.yml`.

---

# Environment Layer

Execution environments are defined in:

```text id="env"
ml/environments/
```

They ensure reproducible runtime behavior for:

* sklearn pipeline execution
* feature engineering steps
* training and evaluation consistency

---

# System Boundaries

This repository intentionally stops at model evaluation.

It does not include:

* online inference
* endpoint deployment
* serving infrastructure

The output is strictly:

> a validated, evaluated regression model artifact

---

# Relationship to Platform

| System          | Responsibility                              |
| --------------- | ------------------------------------------- |
| Databricks repo | Feature engineering + Gold dataset          |
| AzureML repo    | Training + evaluation                       |
| tf-live         | Infrastructure provisioning                 |
| control plane   | Repository generation + CI/CD orchestration |

---

# Summary

This repository implements a strict, reproducible ML system built around:

* notebook-first development as the primary interface
* a single sklearn ElasticNet regression pipeline
* MLTable-based feature ingestion from Databricks Gold layer
* AzureML pipeline execution as the production boundary
* evaluation-only model lifecycle
* explicit versioning via `config.yml`
* GitHub Actions-driven CI/CD orchestration

The `config.yml` file is the critical control surface of the system, ensuring all ML resources remain versioned, traceable, and reproducible across deployments.
