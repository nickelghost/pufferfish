packer {
  required_plugins {
    amazon = {
      version = "~> 1.2.1"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = "~> 1.0.3"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

source "amazon-ebs" "ubuntu-22-04" {
  ami_name             = var.name
  instance_type        = var.instance_type
  region               = var.region
  ssh_username         = "ubuntu"
  iam_instance_profile = "pufferfish-builder"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
}

build {
  name    = var.name
  sources = ["source.amazon-ebs.ubuntu-22-04"]

  provisioner "ansible" {
    playbook_file    = "./ansible/app.yml"
    ansible_env_vars = ["ANSIBLE_NOCOWS=True"]
    use_proxy        = false
  }

  provisioner "shell-local" {
    inline = [
      "aws ssm put-parameter --name '/pufferfish/infra/ami_name' --type String --value ${var.name} --overwrite"
    ]
  }
}
