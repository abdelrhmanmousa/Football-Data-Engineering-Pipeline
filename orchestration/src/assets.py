from dagster import asset, AssetExecutionContext
from dagster_dbt import dbt_assets, DbtCliResource
import os

# Import your actual Ingestion Logic
from ingestion.src.entities.fixtures import FixturesIngestion
from ingestion.src.entities.players import PlayersIngestion
from ingestion.src.entities.standings import StandingsIngestion
# from ingestion.src.entities.players import PlayersIngestion

from .resources import DBT_PROJECT_DIR

# --- 1. INGESTION ASSETS (Python) ---

@asset(compute_kind="python", group_name="ingestion")
def raw_fixtures_json(context: AssetExecutionContext):
    """Fetches Fixtures from API and saves to MinIO"""
    context.log.info("Starting Fixtures Ingestion...")
    
    job = FixturesIngestion()
    job.run()
    
    context.log.info("Finished Fixtures Ingestion.")

@asset(compute_kind="python", group_name="ingestion")
def raw_standings_json(context: AssetExecutionContext):
    """Fetches Standings from API and saves to MinIO"""
    context.log.info("Starting Standings Ingestion...")
    
    job = StandingsIngestion()
    job.run()
    
    context.log.info("Finished Standings Ingestion.")


@asset(compute_kind="python", group_name="ingestion")
def raw_players_json(context: AssetExecutionContext):
    """Fetches Players from API and saves to MinIO"""
    context.log.info("Starting Players Ingestion...")

    job = PlayersIngestion()
    job.run()

    context.log.info("Finished Players Ingestion.")

# --- 2. DBT ASSETS (SQL) ---

@dbt_assets(
    manifest=os.path.join(DBT_PROJECT_DIR, "target", "manifest.json"),
    dagster_dbt_translator=None, # Use default settings
)
def football_dbt_models(context: AssetExecutionContext, dbt: DbtCliResource):
    yield from dbt.cli(["build"], context=context).stream()