data "aws_iam_policy_document" "assume_role_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "put_pufferfish_logs" {
  statement {
    actions = [
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:CreateLogStream",
    ]
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = ["${aws_cloudwatch_log_group.pufferfish_app.arn}:*"]
  }
}

resource "aws_iam_policy" "put_pufferfish_logs" {
  name   = "PutPufferfishLogs"
  policy = data.aws_iam_policy_document.put_pufferfish_logs.json
}

data "aws_iam_policy_document" "put_metrics" {
  statement {
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "put_metrics" {
  name   = "PutMetrics"
  policy = data.aws_iam_policy_document.put_metrics.json
}

data "aws_ssm_parameter" "builds_access_policy_arn" {
  name = "/pufferfish/infra/builds_access_policy_arn"
}

resource "aws_iam_role" "pufferfish" {
  name = "pufferfish"

  assume_role_policy = data.aws_iam_policy_document.assume_role_ec2.json

  managed_policy_arns = [
    nonsensitive(data.aws_ssm_parameter.builds_access_policy_arn.value),
    aws_iam_policy.put_pufferfish_logs.arn,
    aws_iam_policy.put_metrics.arn,
  ]
}

resource "aws_iam_instance_profile" "pufferfish" {
  name = "pufferfish"
  role = aws_iam_role.pufferfish.name
}
