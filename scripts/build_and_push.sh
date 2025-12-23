#!/bin/bash
set -e

# Configuration
AWS_REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

PROJECT_NAME="football-pipeline" # Must match your terraform variable

echo "----------------------------------------------------"
echo "🚀 Starting Build & Push for: $PROJECT_NAME"
echo "   Region: $AWS_REGION"
echo "   Account: $ACCOUNT_ID"
echo "----------------------------------------------------"

# 1. Login to ECR
echo "🔑 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL

# 2. Build & Push INGESTION
echo "📦 Building Ingestion Image..."
docker build -f ingestion/Dockerfile -t ${PROJECT_NAME}-ingestion:latest .

echo "⬆️  Pushing Ingestion Image..."
docker tag ${PROJECT_NAME}-ingestion:latest ${ECR_URL}/${PROJECT_NAME}-ingestion:latest
docker push ${ECR_URL}/${PROJECT_NAME}-ingestion:latest

# 3. Build & Push ANALYTICS (DBT)
echo "📦 Building Analytics (dbt) Image..."
# Note: We must point to analytics folder as context so it can find dbt_project.yml
docker build -f analytics/Dockerfile -t ${PROJECT_NAME}-analytics:latest ./analytics

echo "⬆️  Pushing Analytics Image..."
docker tag ${PROJECT_NAME}-analytics:latest ${ECR_URL}/${PROJECT_NAME}-analytics:latest
docker push ${ECR_URL}/${PROJECT_NAME}-analytics:latest

echo "----------------------------------------------------"
echo "✅ SUCCESS! Images are live in ECR."
echo "----------------------------------------------------"