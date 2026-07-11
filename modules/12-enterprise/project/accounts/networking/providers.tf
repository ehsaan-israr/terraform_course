provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/${var.role_name}"
  }

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Course    = "module-12-enterprise"
    }
  }
}
