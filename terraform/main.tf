terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# ── SNS TOPIC — Alert notifications ──────────────────────────────────────
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts-${var.environment}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ── SNS SUBSCRIPTION — Your email ────────────────────────────────────────
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
# ── CLOUDWATCH BILLING ALARM ─────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  alarm_name          = "${var.project_name}-billing-alarm-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400
  statistic           = "Maximum"
  threshold           = var.billing_threshold
  alarm_description   = "Alert when AWS bill exceeds threshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
# ── DYNAMODB TABLE — Metrics storage ─────────────────────────────────────
resource "aws_dynamodb_table" "metrics" {
  name         = "${var.project_name}-metrics-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "MetricId"
  range_key    = "Timestamp"

  attribute {
    name = "MetricId"
    type = "S"
  }

  attribute {
    name = "Timestamp"
    type = "S"
  }

  ttl {
    attribute_name = "ExpiryTime"
    enabled        = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
# ── IAM ROLE — Lambda execution role ─────────────────────────────────────
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ── IAM POLICY — Lambda permissions ──────────────────────────────────────
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.metrics.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}
# ── LAMBDA PACKAGE — Zip the code ────────────────────────────────────────
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/monitor.py"
  output_path = "${path.module}/../lambda/monitor.zip"
}

# ── LAMBDA FUNCTION — Monitor ─────────────────────────────────────────────
resource "aws_lambda_function" "monitor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-monitor-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "monitor.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.metrics.name
      SNS_TOPIC_ARN  = aws_sns_topic.alerts.arn
      ENVIRONMENT    = var.environment
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ── CLOUDWATCH RULE — Run every hour ─────────────────────────────────────
resource "aws_cloudwatch_event_rule" "monitor_schedule" {
  name                = "${var.project_name}-schedule-${var.environment}"
  description         = "Trigger monitor Lambda every hour"
  schedule_expression = "rate(1 hour)"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ── EVENTBRIDGE TARGET — Point to Lambda ─────────────────────────────────
resource "aws_cloudwatch_event_target" "monitor_target" {
  rule      = aws_cloudwatch_event_rule.monitor_schedule.name
  target_id = "MonitorLambda"
  arn       = aws_lambda_function.monitor.arn
}

# ── LAMBDA PERMISSION — Allow EventBridge to invoke ──────────────────────
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monitor_schedule.arn
}