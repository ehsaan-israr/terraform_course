data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.name_prefix}-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "04-state-management"
  })
}

resource "aws_s3_bucket" "app_artifacts" {
  bucket = local.bucket_name

  tags = merge(local.tags, {
    Name = local.bucket_name
  })
}

resource "aws_s3_bucket_public_access_block" "app_artifacts" {
  bucket = aws_s3_bucket.app_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "app_artifacts" {
  bucket = aws_s3_bucket.app_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_artifacts" {
  bucket = aws_s3_bucket.app_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

