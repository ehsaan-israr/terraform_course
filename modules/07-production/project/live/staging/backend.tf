terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "replace-me-staging-terraform-state"
    key            = "enterprise/staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "replace-me-staging-terraform-locks"
    encrypt        = true
  }
}

