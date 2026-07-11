locals {
  project = "ecosystem-demo"
  region  = "us-east-1"
}

remote_state {
  backend = "s3"

  config = {
    bucket         = "example-terraform-state-${local.project}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    dynamodb_table = "example-terraform-locks-${local.project}"
    encrypt        = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "${local.region}"
}
EOF
}
