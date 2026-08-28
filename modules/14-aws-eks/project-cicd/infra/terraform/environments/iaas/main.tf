locals {
  environment = "iaas"
  name_prefix = "monorepo-${local.environment}"
  common_tags = {
    Environment = local.environment
    ManagedBy   = "terraform"
    Repository  = "terraform-course"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix = local.name_prefix
  cidr_block  = "10.10.0.0/16"
  tags        = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name = "${local.name_prefix}-eks"
  subnet_ids   = concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)
  tags         = local.common_tags
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}
