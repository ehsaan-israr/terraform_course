terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Shared backend settings. State key is set at init time per environment:
    #   glue-jobs/<env>/terraform.tfstate
    #
    # bucket         = "acme-terraform-state"
    # region         = "us-east-1"
    # dynamodb_table = "acme-terraform-locks"
    # encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "glue-jobs"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
