output "vpc_id" {
  value = module.networking.vpc_id
}

output "instance_id" {
  value = module.web.instance_id
}
