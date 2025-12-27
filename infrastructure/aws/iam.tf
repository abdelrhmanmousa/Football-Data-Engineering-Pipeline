# ECS TASK EXECUTION ROLE
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}_ecs_task_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS TASK ROLE (Application Access)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}_ecs_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "ecs_s3_policy" {
  name = "${var.project_name}_ecs_s3_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"],
      Resource = [aws_s3_bucket.data_lake.arn, "${aws_s3_bucket.data_lake.arn}/*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_s3_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_s3_policy.arn
}

# SNOWFLAKE INTEGRATION ROLE (Dynamic Trust)
# FIX: Use merge() to ensure "Condition" key is completely absent if var is empty
resource "aws_iam_role" "snowflake_role" {
  name = "${var.project_name}_snowflake_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      merge(
        {
          Effect = "Allow"
          Action = "sts:AssumeRole"
          Principal = {
            # Trust the Snowflake User ARN if provided, otherwise trust own account (Placeholder)
            AWS = var.snowflake_iam_user != "" ? var.snowflake_iam_user : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          }
        },
        # Conditional Merge: Only add the Condition block if External ID is not empty
        var.snowflake_external_id != "" ? {
          Condition = {
            StringEquals = { "sts:ExternalId" = var.snowflake_external_id }
          }
        } : {}
      )
    ]
  })
}

resource "aws_iam_policy" "snowflake_s3_access" {
  name = "${var.project_name}_snowflake_s3_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket"],
      Resource = [aws_s3_bucket.data_lake.arn, "${aws_s3_bucket.data_lake.arn}/*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "snowflake_attach" {
  role       = aws_iam_role.snowflake_role.name
  policy_arn = aws_iam_policy.snowflake_s3_access.arn
}

# STEP FUNCTIONS ROLE
resource "aws_iam_role" "sfn_role" {
  name = "${var.project_name}_sfn_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

# Basic policy to allow Step Functions to run ECS tasks and pass roles
resource "aws_iam_policy" "sfn_policy" {
  name = "${var.project_name}_sfn_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["ecs:RunTask"],
        Resource = [
          aws_ecs_task_definition.ingestion_task.arn,
          aws_ecs_task_definition.analytics_task.arn
        ]
      },
      {
        Effect = "Allow",
        Action = ["iam:PassRole"],
        Resource = [
          aws_iam_role.ecs_task_execution_role.arn,
          aws_iam_role.ecs_task_role.arn
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["events:PutTargets", "events:PutRule", "events:DescribeRule"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sfn_policy_attach" {
  role       = aws_iam_role.sfn_role.name
  policy_arn = aws_iam_policy.sfn_policy.arn
}