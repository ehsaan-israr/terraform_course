terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "replace-me-dev-terraform-state"
    key            = "enterprise/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "replace-me-dev-terraform-locks"
    encrypt        = true
  }
}

