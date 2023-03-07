resource "aws_autoscaling_group" "pufferfish" {
  lifecycle {
    create_before_destroy = true
  }

  name             = aws_launch_configuration.pufferfish.name
  desired_capacity = 3
  max_size         = 5
  min_size         = 2

  launch_configuration = aws_launch_configuration.pufferfish.name
  vpc_zone_identifier  = data.aws_subnets.default.ids
  target_group_arns    = [aws_lb_target_group.pufferfish.arn]
  health_check_type    = "ELB"
}

data "aws_ami" "pufferfish" {
  filter {
    name   = "name"
    values = [local.ami_name]
  }
}

resource "aws_launch_configuration" "pufferfish" {
  lifecycle {
    create_before_destroy = true
  }

  name_prefix          = "pufferfish-"
  instance_type        = "t3.micro"
  image_id             = data.aws_ami.pufferfish.id
  security_groups      = [aws_security_group.pufferfish.id]
  key_name             = local.key_name
  iam_instance_profile = aws_iam_instance_profile.pufferfish.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }
}
