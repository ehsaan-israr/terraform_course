provider "aws" {
  region = var.aws_region
}

locals {
  tags = {
    Project   = var.project
    ManagedBy = "terraform"
    Module    = "10-advanced"
  }
}

module "networking" {
  source = "./modules/networking"

  project    = var.project
  aws_region = var.aws_region
  cidr_block = "10.42.0.0/16"
  tags       = local.tags
}

module "web_security_group" {
  source = "./modules/security-group"

  project = var.project
  vpc_id  = module.networking.vpc_id
  tags    = local.tags
}

module "web" {
  source = "./modules/compute"

  project             = var.project
  ami_id              = var.ami_id
  instance_type       = var.instance_type
  subnet_id           = module.networking.public_subnet_id
  security_group_ids  = [module.web_security_group.security_group_id]
  associate_public_ip = true
  tags                = local.tags
}
