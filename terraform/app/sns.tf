#tfsec:ignore:aws-sns-enable-topic-encryption
resource "aws_sns_topic" "fish_are_popular_alarm" {
  name = "fish-are-popular-alarm"
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.fish_are_popular_alarm.arn
  protocol  = "email"
  endpoint  = local.notification_email
}
