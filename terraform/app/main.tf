terraform {
  required_version = ">= 1.3"

  backend "s3" {
    region         = "eu-west-1"
    bucket         = "pufferfish-tfstate-mdoxgx2e"
    key            = "app.tfstate"
    dynamodb_table = "pufferfish-tfstate-mdoxgx2e-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.53"
    }
  }
}
