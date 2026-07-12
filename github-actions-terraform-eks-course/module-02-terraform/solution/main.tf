provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

module "storage" {
  source = "./modules/storage"

  bucket_name   = "${local.name_prefix}-storage-${var.bucket_suffix}"
  force_destroy = true
  tags          = local.tags
}
