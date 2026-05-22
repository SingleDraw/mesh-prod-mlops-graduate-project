# Databricks Data Engineering Repository

This repository contains the data engineering layer of the platform built on Databricks. It implements a medallion architecture pipeline (bronze, silver, gold) and is designed as a production-grade Spark system with a clear separation between local development, distributed processing, and ML consumption layers.

It is generated from the control plane and operates as an independent Git repository with its own CI/CD lifecycle.

---

# Role in the Platform

The system is part of a two-domain ML architecture:

```text id="flow-main"
Databricks (Data Engineering) → AzureML (Model Training & Deployment)
```

This repository is responsible for transforming raw data into curated, feature-ready datasets. It does not train models. Instead, it produces the gold layer that becomes the offline feature source for the AzureML pipeline.

---

# Data Ingestion Model

The system ingests raw input from a shared platform storage layer.

The primary ingestion format is Excel-based datasets:

```text id="ingest"
Shared Platform Storage → production_time.xlsx → Bronze Layer
```

This shared storage is the integration point between Databricks and Azure Machine Learning, ensuring both systems operate on a consistent data foundation.

The ingestion process is fully automated and executed through Databricks jobs, not manual uploads.

---

# Medallion Architecture

The pipeline is structured as a strict layered system:

```text id="medallion-flow"
Bronze → Silver → Gold
```

Each layer is persisted as a Delta Lake table inside Databricks.

### Bronze Layer

Raw ingestion from shared storage with minimal transformation.

### Silver Layer

Cleaned, normalized, and validated datasets with applied domain rules.

### Gold Layer

Final feature-ready datasets optimized for consumption by machine learning workloads.

All transformations are implemented using Spark and executed in distributed compute environments.

---

# Storage Strategy

All processed data layers are stored as Delta tables in Databricks.

```text id="storage"
Bronze (Delta)
Silver (Delta)
Gold   (Delta)
```

This ensures:

* ACID compliance
* versioned datasets
* reproducible feature pipelines
* efficient incremental processing

The Gold layer is explicitly treated as a **feature store boundary**, not just an analytical output.

---

# Integration with AzureML

The Gold layer serves as an offline feature store for the AzureML training pipeline.

The flow is:

```text id="aml-flow"
Databricks Gold Delta Table
        ↓
AzureML MLTable Definition
        ↓
Feature Registration
        ↓
Training Pipeline
```

The AzureML repository defines the MLTable abstraction that points to the Gold Delta tables, enabling structured dataset consumption without manual data export.

This ensures:

* consistent feature definitions between training runs
* reproducibility of ML experiments
* decoupling between data engineering and model training

---

# Repository Structure

```text id="structure"
notebooks/
├── local_dev/
└── utils/

src/
├── bronze/
├── silver/
├── gold/
└── utils/

data/
└── dev/

resources/
└── jobs/

.github/
└── workflows/
```

The structure separates experimentation, production transformations, and orchestration logic.

---

# Development Model

Development begins locally in notebooks using Pandas for fast iteration and exploratory analysis.

Once validated, logic is migrated into Spark-based implementations and executed inside Databricks clusters.

```text id="dev-model"
Local Notebook (Pandas)
        ↓
Validation & Feature Design
        ↓
PySpark Migration
        ↓
Databricks Job Execution
        ↓
Delta Table Persistence
```

This model ensures fast iteration without compromising production scalability.

---

# Execution Model

All production transformations are executed through Databricks jobs defined in:

```text id="jobs"
resources/jobs/
```

These jobs are fully declarative and deployed through CI/CD pipelines managed by the control plane.

The repository does not rely on manual Databricks workspace configuration.

---

# CI/CD Integration

GitHub Actions workflows handle:

* deployment of notebooks and jobs
* dataset ingestion triggers
* pipeline execution
* environment synchronization

The system enforces infrastructure-as-code principles for both compute and data pipelines.

---

# Data Contracts

The Gold layer acts as a formal contract between Databricks and AzureML.

It is:

* stable
* versioned
* schema-controlled
* consumable via MLTable abstraction

Any change to Gold structure impacts downstream training pipelines and is therefore treated as a controlled interface.

---

# Shared Storage Dependency

The repository relies on a shared platform storage layer that acts as the integration hub between systems.

This storage is:

* the landing zone for raw inputs (xlsx ingestion)
* the staging layer for cross-system data exchange
* the source of truth for initial dataset distribution

Both Databricks and AzureML consume from this shared layer but interpret data at different abstraction levels.

---

# Operational Flow

```text id="ops-flow"
Control Plane
      ↓
Generate Repository
      ↓
Inject Credentials & Storage Access
      ↓
Ingest XLSX from Shared Storage
      ↓
Run Bronze → Silver → Gold Pipelines
      ↓
Persist Delta Tables
      ↓
Expose Gold as MLTable Source
      ↓
AzureML Consumes Features
```

---

# Relationship to Other Repositories

| System        | Responsibility                          |
| ------------- | --------------------------------------- |
| tf-live       | Infrastructure provisioning             |
| tf-modules    | Infrastructure building blocks          |
| AzureML repo  | Model training and deployment           |
| control plane | Orchestration and repository generation |

---

# Summary

This repository implements a production-grade data engineering system on Databricks built around:

* shared storage ingestion (XLSX-based source system)
* medallion architecture with Delta Lake persistence
* strict separation between transformation layers
* Gold layer serving as offline feature store
* MLTable-based integration with AzureML training pipelines

It acts as the foundational data processing layer for all downstream machine learning workflows in the platform.
