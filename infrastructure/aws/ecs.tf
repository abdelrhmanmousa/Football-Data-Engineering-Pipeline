resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}
# Logs
resource "aws_cloudwatch_log_group" "ingestion_logs" {
  name              = "/ecs/ingestion"
  retention_in_days = 7
  skip_destroy      = false
}

resource "aws_cloudwatch_log_group" "analytics_logs" {
  name              = "/ecs/analytics"
  retention_in_days = 7
  skip_destroy      = false
}

# INGESTION TASK
resource "aws_ecs_task_definition" "ingestion_task" {
  family                   = "ingestion-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "ingestion-container"
    image     = "${aws_ecr_repository.ingestion_repo.repository_url}:latest"
    essential = true
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-group"         = "/ecs/ingestion",
        "awslogs-region"        = var.aws_region,
        "awslogs-stream-prefix" = "ecs",
      }
    }
    environment = [
      { name = "DATA_LAKE_BUCKET", value = aws_s3_bucket.data_lake.id },
      { name = "FOOTBALL_API_KEY", value = var.football_api_key }
    ]
  }])
}
# ANALYTICS TASK
resource "aws_ecs_task_definition" "analytics_task" {
  family                   = "analytics-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "analytics-container"
    image     = "${aws_ecr_repository.analytics_repo.repository_url}:latest"
    essential = true
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-group"         = "/ecs/analytics",
        "awslogs-region"        = var.aws_region,
        "awslogs-stream-prefix" = "ecs",
      }
    }
    environment = [
      { name = "SNOWFLAKE_ACCOUNT_NAME", value = var.snowflake_account_name },
      { name = "SNOWFLAKE_ORGANIZATION_NAME", value = var.snowflake_organization_name },
      { name = "SNOWFLAKE_USER", value = var.snowflake_user },
      { name = "SNOWFLAKE_PASSWORD", value = var.snowflake_password },
      { name = "SNOWFLAKE_ROLE", value = var.snowflake_role },
      { name = "SNOWFLAKE_WAREHOUSE", value = var.snowflake_warehouse },
      { name = "SNOWFLAKE_DATABASE", value = var.snowflake_database },
      { name = "SNOWFLAKE_SCHEMA", value = var.snowflake_schema },
      { name = "DBT_PROFILES_DIR", value = "/app" }
    ]
  }])
}