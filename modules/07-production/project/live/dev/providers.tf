provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::111111111111:role/TerraformExecutionRole"
  }

  default_tags {
    tags = local.common_tags
  }
}

