# 1. The Schedule (The Alarm Clock)
resource "aws_cloudwatch_event_rule" "daily_run" {
  name                = "${var.project_name}-daily-trigger"
  description         = "Triggers the Football Pipeline every day at 02:00 UTC"
  # Cron Syntax: Minutes Hours DayOfMonth Month DayOfWeek Year
  schedule_expression = "cron(0 2 * * ? *)" 
}

# 2. The IAM Role (Permission to press the button)
resource "aws_iam_role" "scheduler_role" {
  name = "${var.project_name}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "events.amazonaws.com" }
    }]
  })
}

# Grant permission to Start the Step Function
resource "aws_iam_role_policy" "scheduler_policy" {
  name = "${var.project_name}-scheduler-policy"
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["states:StartExecution"]
      # Point to the Step Function we created in workflow.tf
      Resource = [aws_sfn_state_machine.pipeline.arn]
    }]
  })
}

# 3. The Target (Connecting the Clock to the Brain)
resource "aws_cloudwatch_event_target" "trigger_pipeline" {
  rule      = aws_cloudwatch_event_rule.daily_run.name
  target_id = "TriggerStepFunction"
  arn       = aws_sfn_state_machine.pipeline.arn
  role_arn  = aws_iam_role.scheduler_role.arn
}