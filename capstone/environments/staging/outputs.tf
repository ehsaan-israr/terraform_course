output "cloudfront_domain_name" {
  value = module.cdn.domain_name
}

output "alb_dns_name" {
  value = module.compute.alb_dns_name
}

output "database_endpoint" {
  value = module.database.endpoint
}

output "redis_endpoint" {
  value = module.cache.primary_endpoint_address
}

output "asset_bucket" {
  value = module.storage.bucket_name
}

output "alerts_topic_arn" {
  value = module.monitoring.alerts_topic_arn
}
