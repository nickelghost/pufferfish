resource "aws_sns_topic" "fish_are_popular_alarm" {
  name = "fish-are-popular-alarm"
}

data "aws_ssm_parameter" "notification_email" {
  name = "/pufferfish/infra/notification_email"
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.fish_are_popular_alarm.arn
  protocol  = "email"
  endpoint  = nonsensitive(data.aws_ssm_parameter.notification_email.value)
}
