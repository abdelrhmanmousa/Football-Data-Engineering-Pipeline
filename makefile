# ==============================================================================
# VARIABLES
# ==============================================================================
COMPOSE_FILE=local_Ops/docker-compose.yaml
ENV_FILE=.env
PROJECT_NAME ?= FootballDataPipeline
AWS_REGION ?= us-east-1

# Export them so scripts and Terraform pick them up automatically
export PROJECT_NAME
export AWS_REGION
# Terraform automatically picks up vars starting with TF_VAR_
export TF_VAR_project_name=$(PROJECT_NAME)

# ==============================================================================
# HELPERS
# ==============================================================================
.PHONY: help
help:
	@echo " FootballDataPipeline (Dagster) - Management Commands"
	@echo "----------------------------------------------------------------"
	@echo "Local Operations:"
	@echo "  make local-start       : Setup folders and start Dagster (Detached)"
	@echo "  make local-stop        : Stop all containers"
	@echo "  make local-logs        : Tail logs for all containers"
	@echo "  make local-shell       : Open a bash shell inside the Dagster Daemon"
	@echo "  make local-dbt         : Run dbt commands manually inside the container"
	@echo "  make local-clean       : !!! Stop containers and DELETE ALL DATA (DBs, Logs)"
	@echo ""
	@echo "Production Operations:"
	@echo "  make prod-build-push   : Build and Push Docker images to ECR"
	@echo "  make prod-infra-apply  : Provision/Update Cloud Infrastructure (Terraform)"
	@echo "  make prod-infra-destroy: Destroy Cloud Infrastructure"
	@echo "  make prod-deploy-all   : Full Release (Infra Apply -> Build -> Push)"
	@echo "----------------------------------------------------------------"

# ==============================================================================
# LOCAL OPERATIONS
# ==============================================================================
.PHONY: local-init
local-init:
	@echo ">>  Initializing configuration..."
	@# Create .env if it doesn't exist
	@touch $(ENV_FILE)
	
	@# Create the Central Data Directory structure
	@# These persist the Database, MinIO files, and DuckDB warehouse
	@echo ">> Creating data directories..."
	@mkdir -p local_Ops/data/minio \
	          local_Ops/data/postgres \
	          local_Ops/data/warehouse

.PHONY: local-start
local-start: local-init
	@echo ">> Starting Dagster Monolith..."
	@docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) up -d --build
	@echo ">>> Services started!"
	@echo "   - Dagster UI:  http://localhost:3000"
	@echo "   - MinIO UI:    http://localhost:9001"


.PHONY: local-stop
local-stop:
	@echo "!! Stopping services..."
	@docker compose -f $(COMPOSE_FILE) down

.PHONY: local-logs
local-logs:
	@docker compose -f $(COMPOSE_FILE) logs -f