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

resource "aws_iam_role" "pufferfish" {
  name = "pufferfish"

  assume_role_policy = data.aws_iam_policy_document.assume_role_ec2.json

  managed_policy_arns = [
    var.builds_access_policy_arn,
    aws_iam_policy.put_pufferfish_logs.arn,
  ]
}

resource "aws_iam_instance_profile" "pufferfish" {
  name = "pufferfish"
  role = aws_iam_role.pufferfish.name
}
