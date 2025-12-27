# The iam Role for the Scheduler
resource "aws_iam_role" "scheduler_role" {
  name = "${var.project_name}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "scheduler_policy" {
  name = "${var.project_name}-scheduler-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["states:StartExecution"]
      Resource = [aws_sfn_state_machine.pipeline.arn]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_attach" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_policy.arn
}

# The Schedule Rule (Daily at Midnight UTC)
resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "${var.project_name}-daily-run"
  description         = "Triggers the Game Market Pipeline every day at midnight"
  schedule_expression = "cron(0 0 * * ? *)" # Runs at 00:00 UTC
}

# The Target (Connect Rule -> Step Function)
resource "aws_cloudwatch_event_target" "sfn_target" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "TriggerStepFunction"
  arn       = aws_sfn_state_machine.pipeline.arn
  role_arn  = aws_iam_role.scheduler_role.arn
}