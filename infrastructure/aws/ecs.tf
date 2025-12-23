resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "/ecs/${var.project_name}"
}

# --- TASK 1: INGESTION ---
resource "aws_ecs_task_definition" "ingestion" {
  family                   = "ingestion"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "ingestion-container"
    image     = "${aws_ecr_repository.ingestion_repo.repository_url}:latest"
    essential = true
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group" = aws_cloudwatch_log_group.logs.name
        "awslogs-region" = var.aws_region
        "awslogs-stream-prefix" = "ingestion"
      }
    }
    environment = [
      { name = "DATA_LAKE_BUCKET", value = aws_s3_bucket.data_lake.bucket },
      { name = "FOOTBALL_API_KEY", value = var.football_api_key }
    ]
  }])
}

# --- TASK 2: ANALYTICS (DBT) ---
resource "aws_ecs_task_definition" "analytics" {
  family                   = "analytics"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "dbt-container"
    image     = "${aws_ecr_repository.analytics_repo.repository_url}:latest"
    essential = true
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group" = aws_cloudwatch_log_group.logs.name
        "awslogs-region" = var.aws_region
        "awslogs-stream-prefix" = "dbt"
      }
    }
    environment = [
      { name = "SNOWFLAKE_ACCOUNT", value = var.snowflake_account_name },
      { name = "SNOWFLAKE_USER", value = var.snowflake_user },
      { name = "SNOWFLAKE_PASSWORD", value = var.snowflake_password }
    ]
  }])
}