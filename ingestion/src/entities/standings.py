from datetime import datetime
from src.connectors.api import FootballAPIClient
from src.connectors.storage import MinioStorage
from src.utils.logger import get_logger

logger = get_logger(__name__)

class YourFeatureNameIngestion:
    def __init__(self):
        # 1. We always need the Driver (API) and the Trunk (Storage)
        self.api = FootballAPIClient()
        self.storage = MinioStorage()

    def run(self):
        # 2. DEFINE CONTEXT: What year/season are we interested in?
        current_year = datetime.now().year
        
        # 3. DEFINE INPUTS: What IDs do we need? 
        # (For now, you can hardcode the leagues like in fixtures.py, 
        # or logic to loop through a list)
        leagues_to_fetch = [39, 140, 78, 135, 61]

        for league_id in leagues_to_fetch:
            logger.info(f"Fetching [FEATURE NAME] for League {league_id}...")

            # 4. PREPARE THE API CALL
            # Look at API Docs: What is the endpoint? What params does it need?
            endpoint = "/ENDPOINT_NAME_HERE"
            params = {
                "league": league_id,
                "season": current_year
                # Add other params if the API requires them
            }

            # 5. CALL THE API
            data = self.api.get(endpoint, params)
            
            if not data:
                logger.warning(f"No data found for League {league_id}")
                continue

            # 6. SAVE THE DATA
            # Define a folder structure that makes sense.
            # Example: raw/standings/2023/39/data.json
            file_path = f"raw/YOUR_FOLDER/season={current_year}/league_id={league_id}/data.json"
            
            self.storage.save_data(data, file_path)