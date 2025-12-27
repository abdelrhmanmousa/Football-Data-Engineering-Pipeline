# 1. THE DATA LAKE (S3)
resource "aws_s3_bucket" "data_lake" {
  # Bucket names must be globally unique. We add a random ID.
  bucket_prefix = "${var.project_name}-lake-"
  force_destroy = true # Allows deleting bucket even if it has files (for learning)
}
data "aws_caller_identity" "current" {}

# 2. THE GARAGE (ECR)
resource "aws_ecr_repository" "ingestion_repo" {
  name                 = "${var.project_name}-ingestion"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "analytics_repo" {
  name                 = "${var.project_name}-analytics"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}