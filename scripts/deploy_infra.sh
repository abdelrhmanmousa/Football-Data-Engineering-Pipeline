#!/bin/bash
set -e

echo "----------------------------------------------------"
echo "🏗️  Deploying AWS Infrastructure..."
echo "----------------------------------------------------"

cd infrastructure/aws

# Initialize if needed
if [ ! -d ".terraform" ]; then
    terraform init
fi

# Apply
# Note: It will ask for 'yes' unless you add -auto-approve
terraform apply

echo "----------------------------------------------------"
echo "🏗️  Deploying Snowflake Infrastructure..."
echo "----------------------------------------------------"

cd ../snowflake

# Initialize if needed
if [ ! -d ".terraform" ]; then
    terraform init
fi

terraform apply

echo "✅ Infrastructure Deployment Complete."