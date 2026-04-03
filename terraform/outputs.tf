output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB metrics table"
  value       = aws_dynamodb_table.metrics.name
}

output "lambda_function_name" {
  description = "Name of the monitor Lambda function"
  value       = aws_lambda_function.monitor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the monitor Lambda function"
  value       = aws_lambda_function.monitor.arn
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge schedule rule"
  value       = aws_cloudwatch_event_rule.monitor_schedule.name
}

output "billing_alarm_name" {
  description = "Name of the CloudWatch billing alarm"
  value       = aws_cloudwatch_metric_alarm.billing_alarm.alarm_name
}