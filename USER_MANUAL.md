# Football Data Engineering Pipeline – User Manual

This manual provides comprehensive instructions for configuring, deploying, and operating the **Football Data Engineering Pipeline**.  
It covers both **local development** (Dagster / DuckDB / MinIO) and **production cloud deployment** (AWS Step Functions / Snowflake / AWS).

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Configuration](#environment-configuration)
3. [Local Development](#local-development)
4. [Cloud Infrastructure Provisioning](#cloud-infrastructure-provisioning)
5. [Code Deployment (Docker & ECR)](#code-deployment-docker--ecr)
6. [CI/CD Workflow](#cicd-workflow)
7. [Operational Guides](#operational-guides)
8. [Troubleshooting](#troubleshooting)

---

## 1. Prerequisites

Ensure the following tools are installed on your workstation:

- **Docker & Docker Desktop** – for local services and container builds  
- **Make** – to run automation commands  
- **Terraform (v1.5+)** – for infrastructure provisioning  
- **AWS CLI** – configured via `aws configure`  
- **Python 3.12+** – for local scripts and dbt

---

## 2. Environment Configuration

The project relies on environment variables for credentials and configuration.

### Create the Environment File:

```bash
cp .env.example .env
```

### Configure Variables: Open ```.env``` and populate the following:
- ```FOOTBALL_API_KEY```: Your API key from API-Football.
- ```AWS_REGION```: Set to af-south-1 (Cape Town).or any region you want 
- ```TF_VAR_snowflake_account_name```: Your Snowflake account (e.g., RC94843).
- ```TF_VAR_snowflake_organization_name```: Your Snowflake org (e.g., JMNXNY).
- ```SNOWFLAKE_USER / SNOWFLAKE_PASSWORD```: Your Snowflake login.
- ```SNOWFLAKE_ROLE```: Usually ACCOUNTADMIN or SYSADMIN.

## 3. Local Development

The local environment replicates the cloud architecture using lightweight tools.
- . **MinIO**: Replaces AWS S3 (Object Storage).
- . **DuckDB**: Replaces Snowflake (OLAP Database).
- . **Dagster**: Replaces Step Functions (Orchestration).

### Starting the Environment
```bash
make local-start
```
#### This command will:

    Initialize local data directories.
    Start Docker containers (MinIO, Dagster, Postgres).
    Initialize local MinIO buckets.

### Accessing Services

. - **Dagster UI**: http://localhost:3000
. - **MinIO Console**: http://localhost:9001 (minioadmin / minioadmin)

### Stopping Services
. - **Stop**: ```make local-stop```
. - **Reset (Delete data)**: ```make local-clean```

## 4. Cloud Infrastructure Provisioning

Cloud deployment uses Terraform to build the AWS and Snowflake environment.

### Infrastructure Provisioning

```bash
make prod-infra-apply
```
#### What happens in the 4 phases:
 - . **Phase 1 (AWS)**: Creates S3 Data Lake and IAM Execution Roles.
 - . **Phase 2 (Snowflake)**: Creates the Storage Integration and IAM OIDC link.
 - . **Phase 3 (AWS)**: Updates IAM Roles to trust Snowflake (Bi-directional trust).
 - . **Phase 4 (Snowflake)**: Creates External Tables, Databases, and Stages.

## 5. Code Deployment

Once infrastructure is ready, push your Python and dbt code to the cloud.

### Build and Push Images
```Bash
make prod-build-push
```
### What this script does:
  - .Authenticates with Amazon ECR.
  - .Builds the ```ingestion``` and ```analytics``` Docker images.
  - .**Note**: It uses an automated retry loop to handle unstable connections to the ```af-south-1``` region.

## 6. CI/CD Workflow

The project is fully automated via GitHub Actions.

- 1. **CI (Quality Gate)**: Triggered on Pull Requests. Runs Python linting (Ruff), Terraform validation, and dbt parse.
- 2. **CD (Deployment)**: Triggered on Merge to main.
       - .. ```CD - Infrastructure```: Automatically runs Terraform Apply.
       - .. ```CD - Application```: Automatically builds and pushes Docker images to ECR.

### Required GitHub Secrets:
    - .``AWS_ACCOUNT_ID``, ``AWS_REGION``,`` ROLE_ARN``
    .``SNOWFLAKE_PASSWORD``, ``SNOWFLAKE_ACCOUNT_NAME``, ``SNOWFLAKE_ORGANIZATION_NAME``
    .``FOOTBALL_API_KEY``

## 7. Operational Guides
### Triggering a Cloud Run
- 1. Navigate to **AWS Console > Step Functions**.
- 2.Select ```football-pipeline-orchestrator```.
- 3.Click **Start Execution**.
- 4.**Graph view**: Monitor the 3 parallel ingestion tasks followed by the dbt transformation.

### Refreshing Snowflake Data
External tables need a manual refresh to see new S3 files:
```SQL
ALTER EXTERNAL TABLE FOOTBALL_LEAGUES_DB.RAW.RAW_FIXTURES REFRESH;
```
## 8. Troubleshooting
### Common Errors
**Terraform Lock**: If a run fails with ``Error acquiring state lock``, run locally:
```terraform force-unlock <LOCK_ID>``` in infrastructure/aws.
- **Snowflake 404**: Check that the account identifier in your .env is correctly formatted (ORG-ACCOUNT).
- **Empty Tables**: If staging tables have data but Dims/Facts are empty, run dbt with the ```--full-refresh``` flag to reset incremental logic.
- **Docker Timeout**: If pushing to ECR fails, simply rerun the command; the script will resume from the last successful layer

