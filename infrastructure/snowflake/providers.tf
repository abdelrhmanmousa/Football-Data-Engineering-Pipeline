terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87"
    }
  
}
  required_version = ">= 1.0"

  backend "s3" {
    bucket       = "football-data-pipeline-tf-state"
    key          = "prod/snowflake/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
  }
}

provider "snowflake" {
  account_name      = var.snowflake_account_name
  organization_name = var.snowflake_organization_name
  user              = var.snowflake_user
  password          = var.snowflake_password
  role              = "ACCOUNTADMIN"
}