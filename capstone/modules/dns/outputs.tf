output "record_fqdns" {
  value = { for key, record in aws_route53_record.this : key => record.fqdn }
}
