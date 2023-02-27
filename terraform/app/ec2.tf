locals {
  instance_count = 2
}

data "aws_ssm_parameter" "pufferfish_ami_name" {
  name = "/pufferfish/infra/ami_name"
}

data "aws_ami" "pufferfish" {
  filter {
    name   = "name"
    values = [data.aws_ssm_parameter.pufferfish_ami_name.value]
  }
}

resource "aws_instance" "pufferfish" {
  count = local.instance_count

  instance_type        = "t3.small"
  ami                  = data.aws_ami.pufferfish.id
  security_groups      = [aws_security_group.pufferfish.name]
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.pufferfish.name

  tags = {
    "Name" = "pufferfish-${count.index}"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }
}
