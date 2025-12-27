# ==============================================================================
# VARIABLES
# ==============================================================================
COMPOSE_FILE=local_Ops/docker-compose.yaml
ENV_FILE=.env
PROJECT_NAME ?= FootballDataPipeline
AWS_REGION ?= af-south-1

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

.PHONY: local-shell
local-shell:
	@echo ">> Entering Dagster Daemon Container..."
	@echo "   (You can run 'dagster job list' or python scripts here)"
	@docker exec -it local_ops-dagster-daemon-1 bash

.PHONY: local-dbt
local-dbt:
	@echo "running dbt..."
	@docker exec -it local_ops-dagster-daemon-1 bash -c "cd /opt/dagster/analytics && dbt build"

.PHONY: local-clean
local-clean: local-stop
	@echo ">> Cleaning up ALL data..."
	@# We use sudo because Docker creates files as root inside these folders
	@sudo rm -rf local_ops/data
	@echo ">>> Clean complete. Project is reset."

# ==============================================================================
# PRODUCTION OPERATIONS
# ==============================================================================
.PHONY: prod-build-push
prod-build-push:
	@echo ">> Building and Pushing Docker Images..."
	@chmod +x scripts/build_and_push.sh
	@./scripts/build_and_push.sh

.PHONY: prod-infra-apply
prod-infra-apply:
	@echo ">> Deploying Infrastructure..."
	@chmod +x scripts/deploy_smart_infra.sh
	@./scripts/deploy_smart_infra.sh

.PHONY: prod-infra-destroy
prod-infra-destroy:
	@echo "!! DESTROYING INFRASTRUCTURE !!"
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@cd infrastructure/aws && terraform destroy -auto-approve
	@cd infrastructure/snowflake && terraform destroy -auto-approve

.PHONY: prod-deploy-all
prod-deploy-all: prod-infra-apply prod-build-push
	@echo ">>> Full Deployment Complete!"


.PHONY: prod-restart
prod-restart:
	@echo ">> Force updating ECS Services..."
	@aws ecs update-service --cluster $(PROJECT_NAME)-cluster --service ingestion-service --force-new-deployment > /dev/null
	@aws ecs update-service --cluster $(PROJECT_NAME)-cluster --service analytics-service --force-new-deployment > /dev/null
	@echo ">>> ECS Services restarting with new images."	
