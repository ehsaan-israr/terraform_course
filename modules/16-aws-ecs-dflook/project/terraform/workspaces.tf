# Environment-wise settings: Terraform workspaces, not tfvars.
#
#   terraform workspace select dev|staging|prod
#
# dflook passes `workspace:` so CI never applies the default workspace.
# S3 backend keeps one key; named workspaces land under env:/<name>/...

locals {
  env = {
    dev = {
      vpc_cidr_block       = "10.90.0.0/16"
      public_subnet_cidrs  = ["10.90.0.0/24", "10.90.1.0/24"]
      private_subnet_cidrs = ["10.90.10.0/24", "10.90.11.0/24"]
      ecs_desired_count    = 0
      enable_nat_gateway   = false
      assign_public_ip     = true
    }
    staging = {
      vpc_cidr_block       = "10.91.0.0/16"
      public_subnet_cidrs  = ["10.91.0.0/24", "10.91.1.0/24"]
      private_subnet_cidrs = ["10.91.10.0/24", "10.91.11.0/24"]
      ecs_desired_count    = 0
      enable_nat_gateway   = false
      assign_public_ip     = true
    }
    prod = {
      vpc_cidr_block       = "10.92.0.0/16"
      public_subnet_cidrs  = ["10.92.0.0/24", "10.92.1.0/24"]
      private_subnet_cidrs = ["10.92.10.0/24", "10.92.11.0/24"]
      ecs_desired_count    = 1
      enable_nat_gateway   = true
      assign_public_ip     = false
    }
  }

  # lookup fallback keeps `terraform validate` working in the default workspace.
  # Plan/apply still fail the guard below unless the workspace is named.
  environment = terraform.workspace
  settings    = lookup(local.env, terraform.workspace, local.env.dev)

  resource_name = "${var.name}-${local.environment}"

  common_tags = merge(var.tags, {
    Environment = local.environment
    ManagedBy   = "terraform"
    Module      = "16-aws-ecs-dflook"
    Workspace   = local.environment
  })

  public_subnets = {
    for index, cidr in local.settings.public_subnet_cidrs :
    var.availability_zones[index] => cidr
  }

  private_subnets = {
    for index, cidr in local.settings.private_subnet_cidrs :
    var.availability_zones[index] => cidr
  }

  # Lab shortcut in non-prod: public IP, no NAT. Prod: private tasks + NAT.
  task_subnet_ids = local.settings.assign_public_ip ? [for subnet in aws_subnet.public : subnet.id] : [for subnet in aws_subnet.private : subnet.id]
}

resource "terraform_data" "workspace_guard" {
  input = terraform.workspace

  lifecycle {
    precondition {
      condition     = contains(keys(local.env), terraform.workspace)
      error_message = "Select workspace dev, staging, or prod. Do not apply the default workspace. Example: terraform workspace select dev"
    }
  }
}
