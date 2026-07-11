resource "aws_ecr_repository" "platform" {
  name                 = "${var.name_prefix}/platform-services"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.name_prefix}-artifacts-${var.account_id}"
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_ssm_parameter" "artifact_bucket" {
  name  = "/platform/artifact-bucket"
  type  = "String"
  value = aws_s3_bucket.artifacts.id
}
