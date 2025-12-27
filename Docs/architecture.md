# 🏗️ System Architecture
This project follows a Modern Data Stack (MDS) approach, emphasizing idempotency, hybrid execution, and cost-efficiency. The pipeline follows an ELT (Extract, Load, Transform) pattern: data is extracted from API-Football, loaded into an S3-based Data Lake in raw JSON format, and transformed directly within the Data Warehouse.

### 🗺️ High Level Design
![Architecture Diagram](Docs/assets/Architecture.png)

## Core Conceptss

## 1. Idempotent Ingestion ("Smart Resume") 🧠
The ingestion layer is designed to be crash-resilient and cost-effective.
- The Problem: API-Football has daily rate limits. If a job fails or the orchestrator restarts, re-fetching the same data wastes API credits.
- The Solution: The S3Writer class performs a HEAD request against S3 (or MinIO) before initiating an API call.

**Logic Flow:**
```Python
if s3_path_exists(current_endpoint, partition):
    # Skip the fetch (Data is already in the Lake)
    log.info("Data already exists. Skipping API call.")
else:
    # Fetch from API and write to S3
    data = fetch_from_api(endpoint)
    s3_writer.upload(data)
```
**Result:** The pipeline is fully idempotent. It can be triggered multiple times a day, but it will only consume API credits for missing or new data.

## 2. Single Source of Truth (SSOT) Configuration 🎯
To prevent "Magic Strings" and configuration drift across different languages (Python, SQL, Terraform), we use a central configuration file: ```config/endpoints.json```.

**Consumers:**

- **Python:** Determines which API routes to hit and where to store the JSON.
- **Terraform:** Reads this file to generate the AWS Step Functions Parallel State, ensuring the orchestrator always matches the available code.
- **Dagster:** Uses the file to dynamically generate Local Assets.

**Benefit:** Adding a new data source (e.g., "Leagues" or "Trophies") only requires editing one JSON file.

## 3. Hybrid Orchestration 🛰️
We use a "Best Tool for the Job" strategy to balance developer experience with production-grade reliability.
| Feature | 🏠 Local (Dagster) | ☁️ Cloud (Step Functions)|
| :--- | :--- | :--- |
| **Cost** | Free (Local Resources) | Serverless (Pay-per-transition) |
| **Paradigm | Asset-based (Software Defined Assets) | Task-based (State Machine) |
| **Environment** | Docker Compose | AWS Fargate (Serverless Containers) |
| **Transform** | dbt-duckdb | dbt-snowflake |


## 4. Hybrid Storage & Hive Partitioning 🗄️

The pipeline abstracts storage so the code remains identical whether running on a laptop or in the cloud.

- **Ingestion Layer**: The ```S3Writer``` detects the environment. If a ```MINIO_ENDPOIN``T is present, it targets local storage; otherwise, it targets AWS S3.
- **Hive Partitioning**: Data is stored using the Hive format to enable efficient "Partition Pruning":
```Text
s3://football-data-lake/raw/fixtures/
├── season=2024/
│   └── league_id=39/
│       └── ingestion_date=2025-01-26/
│           └── data.json
```

**Warehouse Layer:**
- **Dev:** ```dbt-duckdb``` reads JSON directly from the local MinIO bucket.
- **Prod:** ```dbt-snowflake``` reads from Snowflake External Tables, partitioned by the ingestion_date extracted from the S3 path.

