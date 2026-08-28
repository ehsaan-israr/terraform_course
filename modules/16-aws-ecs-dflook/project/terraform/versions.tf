terraform {
  required_version = ">= 1.5.0"

  # Partial backend: CI fills bucket/key/table via dflook backend_config.
  # Local labs: terraform init -backend=false
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
