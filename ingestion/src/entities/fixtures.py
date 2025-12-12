from datetime import datetime
from ingestion.src.utils.config import config
from src.connectors.football_api import FootballAPIClient
from src.connectors.minio_storage import MinioStorage
from src.utils.logger import get_logger

logger = get_logger(__name__)

class FixturesIngestion:
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
            
        day_of_year = datetime.now().timetuple().tm_yday
        # Use modulo to pick a league based on the day number
        index = day_of_year % len(leagues)
        return leagues[index]

    def run(self):
        current_year = datetime.now().year
        league_id = self._get_todays_league()
        
        # 1. Get Today's Date for the folder name
        today_str = datetime.now().strftime("%Y-%m-%d") # e.g., "2023-10-27"
        
        logger.info(f"--- Job Started: Fixtures for League {league_id} | Date: {today_str} ---")

        # 1. Define Request
        # Note: 'fixtures' endpoint in API-Football usually doesn't need pagination 
        # (it sends all matches in one page usually), BUT we use get_all_pages 
        # just to be safe and consistent with your requirement.
        endpoint = "/fixtures"
        params = {
            "league": league_id,
            "season": current_year
        }

        # 2. Fetch Data (The Connector handles Retries & Pagination internally)
        try:
            data = self.api.get_all_pages(endpoint, params)
        except Exception as e:
            logger.critical(f"Stopping job due to API failure: {e}")
            return # Stop cleanly

        if not data:
            logger.warning(f"No fixtures found for League {league_id}")
            return
        
        
        # 3. Dynamic Path Construction (Hive Partitioning)
        # This creates the "Folder for today" you asked for.
        # Structure: raw/ENTITY/partition_keys/filename
        file_path = (
            f"raw/fixtures/"
            f"season={current_year}/"
            f"league_id={league_id}/"
            f"ingestion_date={today_str}/"
            f"data.json"
        )
        
        # 4. Save
        logger.info(f"Saving data to: {file_path}")
        self.storage.save_data(data, file_path)
        logger.info(f"--- Job Finished ---")




        # 3. Save Data
        # Path: raw/fixtures/season=2023/league_id=39/2023-10-25.json
        # date_str = datetime.now().strftime("%Y-%m-%d")
        # file_path = f"raw/fixtures/season={current_year}/league_id={league_id}/{date_str}.json"
        
        # self.storage.save_data(data, file_path)
        # logger.info(f"--- Job Finished: Saved {len(data)} fixtures ---")