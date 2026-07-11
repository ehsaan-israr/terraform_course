output "kms_key_arn" {
  value = aws_kms_key.platform.arn
}

output "web_acl_arn" {
  value = aws_wafv2_web_acl.this.arn
}

output "secret_arns" {
  value = { for name, secret in aws_secretsmanager_secret.this : name => secret.arn }
}
