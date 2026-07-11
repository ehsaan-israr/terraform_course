locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Course      = "aws-terraform-production-engineering"
    Module      = "03-intermediate"
  }

  server_names       = sort(keys(var.servers))
  default_subnet_ids = sort(data.aws_subnets.default.ids)

  server_subnet_ids = {
    for index, name in local.server_names :
    name => local.default_subnet_ids[index % length(local.default_subnet_ids)]
  }
}
