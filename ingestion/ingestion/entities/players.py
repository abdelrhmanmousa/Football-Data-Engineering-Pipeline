from datetime import datetime
from connectors.football_api import FootballAPIClient
from connectors.minio_storage import MinioStorage
from utils.config import config
from utils.logger import get_logger

logger = get_logger(__name__)


class PlayersIngestion:
    def __init__(self):
        self.api = FootballAPIClient()
        self.storage = MinioStorage()

    def _get_todays_league(self):
        """
        Rotates through the WATCHED_LEAGUES from Config.
        """
        leagues = config.WATCHED_LEAGUES
        if not leagues:
            raise ValueError("No leagues defined in Config!")
        da_of_year = datetime.now().timetuple().tm_yday
        # Use modulo to pick a league based on the day number
        index = da_of_year % len(leagues)
        return leagues[index]

    def run(self):
        # 1. Define Context
        # current_year = datetime.now().year
        current_year = 2023  # --- FIXED: Use 2023 season for consistent testing ---
        league_id = self._get_todays_league()

        # 1. Get Today's Date for the folder name

        today_str = datetime.now().strftime("%Y-%m-%d")

        logger.info(
            f"--- Job Started: Players for League {league_id} | Date: {today_str} ---"
        )

        # 2. Prepare API Call
        endpoint = "/players"
        params = {"league": league_id, "season": current_year}

        # 2. Fetch Data (The Connector handles Retries & Pagination internally)
        try:
            data = self.api.get(endpoint, params)
        except Exception as e:
            logger.critical(f"Stopping job due to API failure: {e}")
            return  # Stop cleanly
        if not data:
            logger.warning(f"No players found for League {league_id}")
            return
        # 4. Dynamic Path Construction (Hive Partitioning)
        # Structure: raw/players/season=YYYY/league_id=ID/ingestion_date=YYYY-MM-DD/data.json
        file_path = (
            f"raw/players/"
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
        logger.info("--- Job Finished: Players Ingestion Complete ---")
