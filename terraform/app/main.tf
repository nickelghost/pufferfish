terraform {
  required_version = ">= 1.3"

  backend "s3" {
    key = "app.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.53"
    }
  }
}
