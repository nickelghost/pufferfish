resource "aws_lb" "pufferfish" {
  name = "pufferfish"
  #tfsec:ignore:aws-elb-alb-not-public
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.pufferfish_lb.id]
  subnets                    = data.aws_subnets.default.ids
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "pufferfish" {
  name     = "pufferfish"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    enabled = true
    path    = "/health"
  }
}

resource "aws_lb_target_group_attachment" "pufferfish" {
  count = local.instance_count

  target_group_arn = aws_lb_target_group.pufferfish.arn
  target_id        = aws_instance.pufferfish[count.index].id
}

resource "aws_lb_listener" "pufferfish_http" {
  load_balancer_arn = aws_lb.pufferfish.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = 443
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "pufferfish" {
  load_balancer_arn = aws_lb.pufferfish.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.pufferfish.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "pufferfish" {
  listener_arn = aws_lb_listener.pufferfish.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pufferfish.arn
  }

  condition {
    host_header {
      values = [var.domain]
    }
  }
}

resource "aws_lb_listener_rule" "pufferfish_www_redirect" {
  listener_arn = aws_lb_listener.pufferfish.arn

  action {
    type = "redirect"
    redirect {
      host        = var.domain
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = ["www.${var.domain}"]
    }
  }
}
