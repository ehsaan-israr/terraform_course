module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  aws_region   = var.aws_region
}

module "ecr" {
  source = "./modules/ecr"

  project_name        = var.project_name
  environment         = var.environment
  repository_name     = "capstone-api"
}

module "eks" {
  source = "./modules/eks"

  project_name     = var.project_name
  environment      = var.environment
  cluster_version  = var.cluster_version
  node_count       = var.node_count
  instance_types   = var.instance_types
  vpc_id           = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
}
