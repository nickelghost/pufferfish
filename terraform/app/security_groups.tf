resource "aws_security_group" "pufferfish" {
  name        = "pufferfish"
  description = "Pufferfish app EC2 SG"

  egress {
    description = "allow egress trafic to the internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow app port access from inside the VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  dynamic "ingress" {
    for_each = local.manager_cidr[*]
    content {
      description = "allow SSH from manager IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [local.manager_cidr]
    }
  }
}

resource "aws_security_group" "pufferfish_lb" {
  name        = "pufferfish-lb"
  description = "Pufferfish Application Load Balancer SG"

  ingress {
    description = "allow public HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #tfsec:ignore:aws-ec2-no-public-ingress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow public HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #tfsec:ignore:aws-ec2-no-public-ingress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow access to VPC resources"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }
}
