terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "replace-me-prod-terraform-state"
    key            = "enterprise/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "replace-me-prod-terraform-locks"
    encrypt        = true
  }
}

