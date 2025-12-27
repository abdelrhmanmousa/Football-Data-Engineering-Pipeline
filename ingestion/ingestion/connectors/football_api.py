import requests
import time
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from utils.config import config
from utils.logger import get_logger

logger = get_logger(__name__)

class FootballAPIClient:
    def __init__(self):
        self.base_url = config.BASE_URL
        self.headers = {
            'x-rapidapi-host': "v3.football.api-sports.io",
            'x-rapidapi-key': config.API_KEY
        }
        
        # --- ROBUSTNESS: Handle Network Fails (Retries) ---
        # If the connection fails, it will try 3 times automatically
        self.session = requests.Session()
        retry_strategy = Retry(
            total=3,
            backoff_factor=1, # Wait 1s, then 2s, then 4s
            status_forcelist=[429, 500, 502, 503, 504] # Retry on these errors
        )
        adapter = HTTPAdapter(max_retries=retry_strategy)
        self.session.mount("https://", adapter)
        self.session.mount("http://", adapter)

    def _request(self, endpoint: str, params: dict = None):
        """Internal helper to make a single request."""
        url = f"{self.base_url}{endpoint}"
        try:
            response = self.session.get(url, headers=self.headers, params=params, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            
            # Check for API-Business errors (like "Bad Account")
            if data.get("errors"):
                # If error is just empty list [], it's fine. If it has keys, it's bad.
                if isinstance(data['errors'], dict) and data['errors']: 
                    raise Exception(f"API Error: {data['errors']}")
                if isinstance(data['errors'], list) and len(data['errors']) > 0:
                    raise Exception(f"API Error: {data['errors']}")

            return data
        except Exception as e:
            logger.error(f"Failed request to {endpoint}: {str(e)}")
            raise e

    def get_all_pages(self, endpoint: str, params: dict = None) -> list:
        """
        AUTOMATION: Handles Pagination Automatically.
        If data has 10 pages, this loops 10 times and returns ONE big list.
        """
        if params is None:
            params = {}
            
        all_results = []
        current_page = 1
        
        while True:
            params['page'] = current_page
            logger.info(f"Fetching {endpoint} | Page: {current_page} | Params: {params}")
            
            response_json = self._request(endpoint, params)
            
            # Add this page's results to our big list
            results = response_json.get("response", [])
            all_results.extend(results)
            
            # Pagination Logic
            paging = response_json.get("paging", {})
            total_pages = paging.get("total", 1)
            
            if current_page >= total_pages:
                break # Stop if we reached the last page
            
            current_page += 1
            time.sleep(1) # Be nice to the API (Don't get banned)
            
        return all_results
    
    # Add this method to class FootballAPIClient
    
    def get(self, endpoint: str, params: dict = None) -> list:
        """
        Simple GET for endpoints that DO NOT support pagination (like /fixtures).
        """
        if params is None:
            params = {}
            
        logger.info(f"Fetching {endpoint} | Params: {params}")
        
        # We call the internal _request helper we already wrote
        response_json = self._request(endpoint, params)
        
        # Return just the data list
        return response_json.get("response", [])    