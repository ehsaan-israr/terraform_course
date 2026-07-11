provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::333333333333:role/TerraformExecutionRole"
  }

  default_tags {
    tags = local.common_tags
  }
}

