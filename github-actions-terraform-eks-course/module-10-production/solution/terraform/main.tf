data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-${var.environment}-${var.ecr_repository_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ssm_parameter" "environment_config" {
  name  = "/${var.project_name}/${var.environment}/node_count"
  type  = "String"
  value = tostring(var.node_count)
}

resource "aws_ssm_parameter" "instance_types" {
  name  = "/${var.project_name}/${var.environment}/instance_types"
  type  = "String"
  value = join(",", var.instance_types)
}
