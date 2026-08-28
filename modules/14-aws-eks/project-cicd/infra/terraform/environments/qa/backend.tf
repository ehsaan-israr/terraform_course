terraform {
  backend "s3" {
    bucket         = "REPLACE_ME-tfstate"
    key            = "qa/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "REPLACE_ME-tflock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "qa"
      ManagedBy   = "terraform"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
