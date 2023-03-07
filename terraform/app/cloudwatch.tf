#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "pufferfish_app" {
  name              = "pufferfish/app"
  retention_in_days = var.log_retention_in_days
}

resource "aws_cloudwatch_metric_alarm" "fish_are_popular" {
  alarm_name          = "fish-are-popular"
  alarm_description   = "Fish are pupular!!!!111"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "Pufferfish"
  metric_name         = "FishViews"
  statistic           = "Sum"
  threshold           = 20
  evaluation_periods  = 1
  period              = 60
  alarm_actions       = [aws_sns_topic.fish_are_popular_alarm.arn]
}
