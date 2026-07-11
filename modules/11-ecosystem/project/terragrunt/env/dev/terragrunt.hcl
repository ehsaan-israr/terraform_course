include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/vpc"
}

inputs = {
  name       = "ecosystem-dev"
  cidr_block = "10.60.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]

  tags = {
    Environment = "dev"
    ManagedBy   = "terragrunt"
  }
}
