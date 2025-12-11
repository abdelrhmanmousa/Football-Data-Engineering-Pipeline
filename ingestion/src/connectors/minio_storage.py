import boto3
import json
from io import BytesIO
from src.config import config
from src.utils.logger import get_logger

logger = get_logger(__name__)

class MinioStorage:
    def __init__(self):
        self.s3_client = boto3.client(
            "s3",
            endpoint_url=config.S3_ENDPOINT,
            aws_access_key_id=config.AWS_ACCESS_KEY,
            aws_secret_access_key=config.AWS_SECRET_KEY
        )
        self.bucket = config.BUCKET_NAME
        self._ensure_bucket_exists()

    def _ensure_bucket_exists(self):
        """Check if bucket exists, create if not (MinIO specific convenience)."""
        try:
            self.s3_client.head_bucket(Bucket=self.bucket)
        except:
            logger.info(f"Bucket {self.bucket} not found. Creating it...")
            self.s3_client.create_bucket(Bucket=self.bucket)

    def save_data(self, data: list, file_path: str):
        """
        Uploads list of dictionaries as a JSON file.
        path example: 'raw/fixtures/2023/premier_league.json'
        """
        try:
            json_buffer = json.dumps(data, indent=4).encode('utf-8')
            file_obj = BytesIO(json_buffer)
            
            self.s3_client.upload_fileobj(
                file_obj,
                self.bucket,
                file_path
            )
            logger.info(f"Successfully uploaded data to s3://{self.bucket}/{file_path}")
        except Exception as e:
            logger.error(f"Failed to upload to S3: {e}")
            raise e