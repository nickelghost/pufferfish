data "aws_iam_policy_document" "assume_role_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "get_pufferfish_builds" {
  statement {
    actions = ["s3:GetObject", "s3:ListBucket"]
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = ["${aws_s3_bucket.builds.arn}*"]
  }
}

resource "aws_iam_policy" "get_pufferfish_builds" {
  name   = "GetPufferfishBuilds"
  policy = data.aws_iam_policy_document.get_pufferfish_builds.json
}

resource "aws_ssm_parameter" "builds_access_policy_arn" {
  name  = "/pufferfish/infra/builds_access_policy_arn"
  type  = "String"
  value = aws_iam_policy.get_pufferfish_builds.arn
}

resource "aws_iam_role" "pufferfish_builder" {
  name                = "pufferfish-builder"
  assume_role_policy  = data.aws_iam_policy_document.assume_role_ec2.json
  managed_policy_arns = [aws_iam_policy.get_pufferfish_builds.arn]
}

resource "aws_iam_instance_profile" "pufferfish_builder" {
  name = "pufferfish-builder"
  role = aws_iam_role.pufferfish_builder.name
}
