# Lightweight infrastructure footprint for pipeline validation.
# In a full course path, this extends networking/EKS from prior modules.

resource "aws_s3_bucket" "app_artifacts" {
  bucket = "${var.project_name}-${var.environment}-artifacts-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "app_artifacts" {
  bucket = aws_s3_bucket.app_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_ssm_parameter" "cluster_name" {
  name  = "/${var.project_name}/${var.environment}/cluster_name"
  type  = "String"
  value = var.cluster_name
}
