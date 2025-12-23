
output "s3_bucket_name" {
  value = aws_s3_bucket.data_lake.bucket
}

output "snowflake_role_arn" {
  value = aws_iam_role.snowflake_role.arn
}

output "ingestion_repo_url" {
  value = aws_ecr_repository.ingestion_repo.repository_url
}

output "analytics_repo_url" {
  value = aws_ecr_repository.analytics_repo.repository_url
}

output "github_actions_role_arn" {
  description = "The ARN of the IAM Role for GitHub Actions OIDC"
  value       = aws_iam_role.github_actions_role.arn
}