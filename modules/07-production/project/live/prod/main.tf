locals {
  environment = "prod"
  name_prefix = "acme-payments-prod-use1"

  common_tags = {
    Application = "payments"
    Environment = local.environment
    ManagedBy   = "Terraform"
    Owner       = "platform"
    CostCenter  = "eng-platform"
  }
}

module "networking" {
  source = "../../modules/networking"

  name_prefix         = local.name_prefix
  vpc_cidr            = "10.30.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"]
  tags                = local.common_tags
}

module "app" {
  source = "../../modules/app"

  name_prefix         = local.name_prefix
  environment         = local.environment
  vpc_id              = module.networking.vpc_id
  allowed_http_cidrs  = ["10.30.0.0/16"]
  active_color        = var.active_color
  tags                = local.common_tags
}

