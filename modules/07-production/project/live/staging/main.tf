locals {
  environment = "staging"
  name_prefix = "acme-payments-staging-use1"

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
  vpc_cidr            = "10.20.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs = ["10.20.0.0/24", "10.20.1.0/24"]
  tags                = local.common_tags
}

module "app" {
  source = "../../modules/app"

  name_prefix         = local.name_prefix
  environment         = local.environment
  vpc_id              = module.networking.vpc_id
  allowed_http_cidrs  = ["10.20.0.0/16"]
  active_color        = var.active_color
  tags                = local.common_tags
}

