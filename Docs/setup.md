# 💻 Local Development Guide

This guide details how to spin up the entire Data Pipeline locally using Docker. In this mode, we emulate the cloud services to ensure zero-cost development:

*   **AWS S3** $\rightarrow$ **MinIO**
*   **Snowflake** $\rightarrow$ **DuckDB**
*   **ECS Fargate** $\rightarrow$ **Docker Containers**
*   **Step Functions** $\rightarrow$ **Dagster Daemon**

## 1. Prerequisites

Ensure you have the following installed:
*   **Docker Desktop** (or Engine) with Docker Compose v2+
*   **Make** (standard on Linux/Mac, install via Chocolatey on Windows)
*   **Git**

## 2. Configuration

1.  Copy the example environment file:
    ```bash
    cp .env.example .env
    ```

2.  Open `.env` and configure the following:
    ```ini
    # Essential for Ingestion
    FOOTBALL_API_KEY=your_api_key_here

    # Local MinIO Credentials (Defaults are fine for local)
    MINIO_ROOT_USER=minioadmin
    MINIO_ROOT_PASSWORD=minioadmin
    DATA_LAKE_BUCKET=rawg-lake
    ```

## 3. Starting the Stack

We use a `Makefile` to simplify Docker commands.

1.  **Initialize and Start**:
    ```bash
    make local-start
    ```
    *   *What happens?* 
        *   Creates local data directories in `local_ops/data/` (persists data across restarts).
        *   Starts Postgres (Dagster DB), MinIO (Object Storage), and the Dagster Daemon.
        *   Automatically creates the `football-lake` bucket in MinIO.

2.  **Verify Services**:
    *   **Dagster UI**: [http://localhost:3000](http://localhost:3000)
    *   **MinIO Console**: [http://localhost:9001](http://localhost:9001) (User/Pass: `minioadmin` / `minioadmin`)

## 4. Operational Workflow

### A. Triggering a Daily Run
The pipeline is Partitioned. You don't just "run it"; you run it for a specific date.

1.  Go to **Dagster UI** > **Overview** > **Jobs**.
2.  Click `daily_football_leagues`.
3.  Click **Materialize All**.
4.  Click the **Partition Icon** (top right of the launch modal) and select yesterday's date.
5.  Click **Launch Run**.

**What happens next?**
1.  **Ingestion**: Python scripts fetch JSON for that date and upload it to MinIO (`s3://football-lake/raw/...`).
2.  **dbt**: Once ingestion finishes, dbt runs. It uses the `dbt-duckdb` adapter to read those JSON files directly from MinIO and creates tables.

### B. Accessing the Data (DuckDB)
Since DuckDB runs inside the container, the database file is persisted at `local_ops/data/warehouse/football.duckdb`.

You can query it in two ways:
1.  **Via dbt**: Run `make local-dbt` to open a shell, then use `dbt show --select fct_games`.
2.  **Via IDE**: If you have a DuckDB client, you can try connecting to the `.duckdb` file in the `local_ops/data` folder (ensure the container is stopped first to avoid lock issues).

## 5. Troubleshooting

*   **"Bucket does not exist"**: The `create_buckets` container usually handles this. If it failed, log into MinIO Console (localhost:9001) and create a bucket named `football-lake` manually.
*   **Database Locks**: If DuckDB fails with lock errors, ensure no other process (like DBeaver) is holding the `.duckdb` file open.
*   **API Rate Limits**: The pipeline uses `tenacity` to retry, but RAWG has a limit. If you see 429 errors, wait a few minutes.

## 6. Cleanup

To stop containers:
```bash
make local-stop
```

To **NUKE** everything (delete containers, volumes, and downloaded data):
```bash
make local-clean
```
*Warning: This deletes your local Data Lake and Warehouse files.*