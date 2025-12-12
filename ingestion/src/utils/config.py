# ingestion/src/config.py
import os

class Config:
    # --- CHANGED: Renamed to generic API names ---
    API_KEY = os.getenv("FOOTBALL_API_KEY")
    # Assuming you are using API-Football (based on your diagram)
    BASE_URL = "https://v3.football.api-sports.io" 
    
    # --- Storage Config (Kept mostly the same) ---
    AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY_ID") or os.getenv("MINIO_ROOT_USER")
    AWS_SECRET_KEY = os.getenv("AWS_SECRET_ACCESS_KEY") or os.getenv("MINIO_ROOT_PASSWORD")

    _raw_endpoint = os.getenv("MINIO_ENDPOINT")

    if _raw_endpoint:
        # distinct logic for local MinIO vs Cloud S3
        if not _raw_endpoint.startswith("http"):
            S3_ENDPOINT = f"http://{_raw_endpoint}"
        else:
            S3_ENDPOINT = _raw_endpoint
    else:
        S3_ENDPOINT = None

    BUCKET_NAME = os.getenv("DATA_LAKE_BUCKET", "football-lake")
    
    # LOGIC CONFIGURATION
    # We put the list here. In the future, you can load this from a DB or a file easily.
    # 39=Premier League, 140=La Liga, 78=Bundesliga, 135=Serie A, 61=Ligue 1
    WATCHED_LEAGUES = [39, 140, 78, 135, 61] 

    def validate(self):
        if not self.API_KEY:
            raise ValueError("Missing FOOTBALL_API_KEY in environment variables.")
        if self.S3_ENDPOINT and (not self.AWS_ACCESS_KEY or not self.AWS_SECRET_KEY):
             raise ValueError("Missing Storage Credentials for MinIO/Custom S3.")
        return True

config = Config()