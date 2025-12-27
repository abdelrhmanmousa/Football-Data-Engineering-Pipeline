# variable "snowflake_account_name" { type = string }
# variable "snowflake_organization_name" { type = string }
# variable "snowflake_user" { type = string }
# variable "snowflake_password" { type = string }

# We need the S3 Bucket URL from the AWS step
# variable "s3_bucket_url" { 
#   type = string 
#   description = "s3://my-bucket-name/raw/"
# }

# We need the AWS Role ARN to allow Snowflake to read S3

variable "snowflake_account_name" {
  type = string
}

variable "snowflake_organization_name" {
  type = string
}

variable "snowflake_user" {
  type = string
}

variable "snowflake_password" {
  type      = string
  sensitive = true
}

variable "snowflake_role" {
  type    = string
  default = "ACCOUNTADMIN"
}

# Inputs from AWS Stack
variable "s3_bucket_name" {
  type = string
}

variable "aws_role_arn" {
  type = string
}