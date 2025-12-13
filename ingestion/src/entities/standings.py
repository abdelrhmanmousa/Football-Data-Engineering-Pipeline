from datetime import datetime
from ingestion.src.utils.config import config
from ingestion.src.connectors.football_api import FootballAPIClient
from ingestion.src.connectors.minio_storage import MinioStorage
from ingestion.src.utils.logger import get_logger

logger = get_logger(__name__)

class StandingsIngestion:
    """
    Handles fetching Football League Standings.
    Strategy: Fetches ALL watched leagues every run (usually daily).
    """
    def __init__(self):
        self.api = FootballAPIClient()
        self.storage = MinioStorage()

    def run(self):
        # 1. Define Context
        current_year = datetime.now().year
        today_str = datetime.now().strftime("%Y-%m-%d")
        
        # We fetch ALL leagues for standings to keep the dashboard fresh
        leagues = config.WATCHED_LEAGUES

        logger.info(f"--- Job Started: Standings for {len(leagues)} leagues ---")

        for league_id in leagues:
            logger.info(f"Processing Standings for League {league_id}...")

            # 2. Prepare API Call
            endpoint = "/standings"
            params = {
                "league": league_id,
                "season": current_year
            }

            # 3. Fetch Data (Robust: Handles Retries & Pagination)
            try:
                # We use get_all_pages even if standings is usually 1 page,
                # just to be safe and consistent.
                data = self.api.get_all_pages(endpoint, params)
            except Exception as e:
                logger.error(f"Skipping League {league_id} due to error: {e}")
                continue # Skip this league, try the next one

            if not data:
                logger.warning(f"No standings found for League {league_id}")
                continue

            # 4. Construct Dynamic Path (Hive Partitioning)
            # Structure: raw/standings/season=YYYY/league_id=ID/ingestion_date=YYYY-MM-DD/data.json
            file_path = (
                f"raw/standings/"
                f"season={current_year}/"
                f"league_id={league_id}/"
                f"ingestion_date={today_str}/"
                f"data.json"
            )

            # 5. Save Data
            try:
                self.storage.save_data(data, file_path)
            except Exception as e:
                logger.error(f"Failed to save data for League {league_id}: {e}")

        logger.info("--- Job Finished: Standings Ingestion Complete ---")