import argparse
from utils.config import config
from utils.logger import get_logger
from entities.fixtures import FixturesIngestion
from entities.standings import StandingsIngestion
from entities.players import PlayersIngestion

# Initialize logger
logger = get_logger("main")

def main():
    # 1. Validate environment
    try:
        config.validate()
    except ValueError as e:
        logger.critical(f"Configuration Error: {e}")
        exit(1)

    # 2. Parse Arguments
    parser = argparse.ArgumentParser(description="Football Data Ingestion Pipeline")
    parser.add_argument(
        "--job", 
        type=str, 
        choices=["fixtures", "standings", "players"], 
        required=True, 
        help="Which entity to ingest"
    )
    
    args = parser.parse_args()

    # 3. Route to the right Entity (The Driver)
    logger.info(f"Starting job: {args.job}")
    
    if args.job == "fixtures":
        job = FixturesIngestion()
        job.run()
    
    elif args.job == "standings":
        job = StandingsIngestion()
        job.run()
        
    elif args.job == "players":
        jon = PlayersIngestion()
        jon.run()
            
        # logger.warning("Standings ingestion not implemented yet")
        # pass
        
    logger.info("Pipeline finished.")

