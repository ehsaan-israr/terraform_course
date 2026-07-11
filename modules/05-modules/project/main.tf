locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "05-modules"
  })
}

module "vpc" {
  source = "./modules/vpc"

  name                 = "${var.name}-${var.environment}"
  cidr_block           = var.vpc_cidr_block
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  tags                 = local.common_tags
}

module "security_groups" {
  source = "./modules/security-groups"

  name               = "${var.name}-${var.environment}"
  vpc_id             = module.vpc.vpc_id
  app_port           = var.app_port
  db_port            = 5432
  allowed_http_cidrs = ["0.0.0.0/0"]
  tags               = local.common_tags
}

module "ecs" {
  source = "./modules/ecs"

  name              = "${var.name}-${var.environment}"
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_groups.app_security_group_id
  container_port    = var.app_port
  desired_count     = 1
  create_service    = false
  tags              = local.common_tags
}

module "rds" {
  source = "./modules/rds"

  name                 = "${var.name}-${var.environment}"
  subnet_ids           = module.vpc.private_subnet_ids
  db_security_group_id = module.security_groups.database_security_group_id
  db_username          = var.db_username
  tags                 = local.common_tags
}

