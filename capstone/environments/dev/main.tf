provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

locals {
  name = "${var.project}-${var.environment}"
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "networking" {
  source = "../../modules/networking"

  name               = local.name
  vpc_cidr           = "10.10.0.0/16"
  enable_nat_gateway = true
  tags               = local.tags
}

module "security" {
  source = "../../modules/security"

  name         = local.name
  waf_scope    = "CLOUDFRONT"
  secret_names = ["database/password", "app/jwt"]
  tags         = local.tags
}

module "storage" {
  source = "../../modules/storage"

  name          = local.name
  force_destroy = true
  tags          = local.tags
}

module "compute" {
  source = "../../modules/compute-ecs"

  name               = local.name
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  container_image    = var.container_image
  container_port     = 8080
  desired_count      = 1
  cpu                = 512
  memory             = 1024
  health_check_path  = "/health"

  environment_variables = merge(var.app_environment_variables, {
    ENVIRONMENT = var.environment
    ASSET_BUCKET = module.storage.bucket_name
  })

  secrets = [
    {
      name       = "DATABASE_PASSWORD"
      value_from = module.security.secret_arns["database/password"]
    }
  ]

  tags = local.tags
}

module "database" {
  source = "../../modules/database"

  name                       = local.name
  vpc_id                     = module.networking.vpc_id
  subnet_ids                  = module.networking.private_subnet_ids
  allowed_security_group_ids = [module.compute.service_security_group_id]
  database_name              = "app"
  username                   = "app"
  password                   = var.database_password
  instance_class             = "db.t4g.micro"
  allocated_storage          = 20
  multi_az                   = false
  backup_retention_days      = 3
  deletion_protection        = false
  tags                       = local.tags
}

module "cache" {
  source = "../../modules/cache"

  name                       = local.name
  vpc_id                     = module.networking.vpc_id
  subnet_ids                  = module.networking.private_subnet_ids
  allowed_security_group_ids = [module.compute.service_security_group_id]
  node_count                 = 1
  auth_token                 = var.redis_auth_token
  tags                       = local.tags
}

module "cdn" {
  source = "../../modules/cdn"

  name               = local.name
  origin_domain_name = module.compute.alb_dns_name
  domain_aliases     = var.domain_name == "" ? [] : [var.domain_name]
  certificate_arn    = var.certificate_arn
  web_acl_id         = module.security.web_acl_arn
  tags               = local.tags
}

module "dns" {
  source = "../../modules/dns"

  zone_id = var.route53_zone_id
  records = var.domain_name == "" ? {} : {
    app = {
      name    = var.domain_name
      type    = "CNAME"
      ttl     = 300
      records = [module.cdn.domain_name]
    }
  }
}

module "monitoring" {
  source = "../../modules/monitoring"

  name                    = local.name
  alb_arn_suffix          = module.compute.alb_arn_suffix
  target_group_arn_suffix = module.compute.target_group_arn_suffix
  cluster_name            = module.compute.cluster_name
  service_name            = module.compute.service_name
  alarm_email             = var.alarm_email
  tags                    = local.tags
}
