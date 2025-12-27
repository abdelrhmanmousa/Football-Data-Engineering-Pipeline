# 📊 Data Warehouse Design & Architecture

The Data Warehouse for the Football Pipeline is designed using the **Kimball Methodology** (Star Schema) combined with a **Modern Data Stack** approach (ELT). It prioritizes **Schema-on-Read** flexibility for ingestion and **Incremental Processing** for transformation to minimize cloud costs.

---

## 🏗 Layered Architecture

We strictly separate concerns into three distinct layers: **Raw (Storage)**, **Staging (Cleaning)**, and **Marts (Business Logic)**.

### 1. Raw Layer (Data Lake Integration)
*   **Technology:** Snowflake External Tables pointing to AWS S3.
*   **Format:** Semi-structured JSON.
*   **Optimization:** **Hive-Style Partitioning**.
    *   **S3 Path Structure:** `s3://bucket/raw/fixtures/season=2023/league_id=39/ingestion_date=2023-10-01/data.json`
    *   **Snowflake Definition:** `PARTITION BY (ingestion_date)`
*   **Benefit:** When running backfills or daily loads, Snowflake uses **Partition Pruning** to scan only the specific folders required, ignoring terabytes of historical history.

### 2. Staging Layer (Normalization)
*   **Technology:** dbt Views (`materialized='view'`).
*   **Purpose:**
    *   Flattens nested JSON arrays (e.g., `UNNEST(players.statistics)`).
    *   Renames API keys to business-friendly names (e.g., `fixture.status.long` → `match_status`).
    *   Casts data types (Strings to Timestamps).
*   **Abstraction:** This layer creates a firewall between the messy API structure and the clean business logic. If the API changes, we only fix Staging.

### 3. Marts Layer (Star Schema & Incremental Strategy)
*   **Technology:** dbt Incremental Tables (`materialized='incremental'`).
*   **Model:** Star Schema (Facts and Dimensions).

#### ⚡ Performance Strategy: The "Lookback Window"
Since football data can change slightly after ingestion (e.g., a match status updating from 'Live' to 'Finished'), we use a rolling window strategy:

*   **The Logic:**
    ```sql
    where ingestion_date >= date_add(max(last_loaded_at), interval -3 day) 
    ```
    (this is syntax works for DuckDB but the same logic for snowflake)
*   **The Benefit:** This ensures late-arriving data or corrections are captured without needing a full refresh of the entire warehouse history.

---

## 🌟 Data Model (Star Schema)

We organize data into **Facts** (Events) and **Dimensions** (Context).

### Dimensions (The "Nouns")
| Table | Description | Update Strategy |
| :--- | :--- | :--- |
| **`dim_leagues`** | League metadata (Name, Country, Season). | Incremental (Merge) |
| **`dim_teams`** | Team profiles extracted from fixtures/standings. | Incremental (Merge) |
| **`dim_players`** | Unique player profiles (Name, Nationality). | Incremental (Merge) |
| **`dim_venues`** | Stadium details (City, Capacity). | Incremental (Merge) |

### Facts (The "Verbs")
| Table | Description | Grain |
| :--- | :--- | :--- |
| **`fct_matches`** | The core event log. Scores, Status, Dates. | One row per Match. |
| **`fct_season_standings`** | The final league table results. | One row per Team per Season. |
| **`fct_player_season_stats`** | Aggregated performance (Goals, Cards). | One row per Player per Team per Season. |
| **`fct_transfers`** | Derived movement of players between teams. | One row per Transfer event. |

### Bridge Tables
*   **`bridge_team_leagues`**: Handles the Many-to-Many relationship where one team (e.g., Man City) plays in multiple tournaments (Premier League + Champions League) in the same season.

---

## ✅ Data Quality & Contracts

We treat data quality as code using `dbt test`. The pipeline fails immediately if core assumptions are violated.

*   **Primary Key Integrity:** `unique` and `not_null` tests on all Surrogate Keys (`team_key`, `fixture_key`).
*   **Referential Integrity:** Facts must link to valid Dimensions.
*   **Domain Validity:**
    *   `match_status`: Must be a valid API status (e.g., 'Match Finished', 'Postponed').
    *   `scores`: Cannot be negative.