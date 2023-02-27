#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "pufferfish_app" {
  name              = "pufferfish/app"
  retention_in_days = var.log_retention_in_days
}
