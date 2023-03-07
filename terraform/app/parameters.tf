locals {
  domain                   = nonsensitive(data.aws_ssm_parameter.domain.value)
  ami_name                 = nonsensitive(data.aws_ssm_parameter.ami_name.value)
  manager_cidr             = nonsensitive(data.aws_ssm_parameter.manager_cidr.value)
  key_name                 = nonsensitive(data.aws_ssm_parameter.key_name.value)
  builds_access_policy_arn = nonsensitive(data.aws_ssm_parameter.builds_access_policy_arn.value)
  log_retention_in_days    = nonsensitive(data.aws_ssm_parameter.log_retention_in_days.value)
  notification_email       = nonsensitive(data.aws_ssm_parameter.notification_email.value)
}

data "aws_ssm_parameter" "domain" {
  name = "/pufferfish/infra/domain"
}

data "aws_ssm_parameter" "ami_name" {
  name = "/pufferfish/infra/ami_name"
}

data "aws_ssm_parameter" "manager_cidr" {
  name = "/pufferfish/infra/manager_cidr"
}

data "aws_ssm_parameter" "key_name" {
  name = "/pufferfish/infra/key_name"
}

data "aws_ssm_parameter" "builds_access_policy_arn" {
  name = "/pufferfish/infra/builds_access_policy_arn"
}

data "aws_ssm_parameter" "log_retention_in_days" {
  name = "/pufferfish/infra/log_retention_in_days"
}

data "aws_ssm_parameter" "notification_email" {
  name = "/pufferfish/infra/notification_email"
}
