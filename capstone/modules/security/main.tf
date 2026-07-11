resource "aws_kms_key" "platform" {
  description             = "KMS key for ${var.name} platform secrets"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_alias" "platform" {
  name          = "alias/${var.name}-platform"
  target_key_id = aws_kms_key.platform.key_id
}

resource "aws_secretsmanager_secret" "this" {
  for_each = toset(var.secret_names)

  name       = "/${var.name}/${each.value}"
  kms_key_id = aws_kms_key.platform.arn

  tags = var.tags
}

resource "aws_wafv2_web_acl" "this" {
  name  = "${var.name}-web-acl"
  scope = var.waf_scope

  default_action {
    allow {}
  }

  rule {
    name     = "aws-common-rules"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-web-acl"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}
