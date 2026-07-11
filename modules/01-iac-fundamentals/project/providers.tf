provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Course      = "aws-terraform-production-engineering"
      Module      = "01-iac-fundamentals"
    }
  }
}
