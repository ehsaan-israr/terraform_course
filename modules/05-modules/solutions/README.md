# Module 5 Solutions - Terraform Modules

These answers correspond to `../exercises/README.md` and use the project in
`../project`.

## Exercise 1: Trace module dependencies

The root module composes child modules in `project/main.tf`:

```text
root
 |-- module.vpc
 |-- module.security_groups
 |-- module.ecs
 `-- module.rds
```

Dependency wiring:

| Consumer | Input | Producer output |
| --- | --- | --- |
| `module.security_groups` | `vpc_id` | `module.vpc.vpc_id` |
| `module.ecs` | `subnet_ids` | `module.vpc.private_subnet_ids` |
| `module.ecs` | `security_group_id` | `module.security_groups.app_security_group_id` |
| `module.rds` | `subnet_ids` | `module.vpc.private_subnet_ids` |
| `module.rds` | `db_security_group_id` | `module.security_groups.database_security_group_id` |

The VPC module creates the VPC:

```hcl
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
```

The root module owns cross-module wiring because it knows the composition. Child
modules should expose small, useful outputs and accept inputs; they should not
reach sideways into sibling modules. That keeps modules reusable and testable.

## Exercise 2: Add input validation

Add validations to `project/modules/vpc/variables.tf`.

For public subnets:

```hcl
variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks, one per availability zone."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
    error_message = "Provide one public subnet CIDR per availability zone."
  }

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Every public subnet CIDR must be valid CIDR notation."
  }
}
```

For private subnets:

```hcl
variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks, one per availability zone."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.availability_zones)
    error_message = "Provide one private subnet CIDR per availability zone."
  }

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Every private subnet CIDR must be valid CIDR notation."
  }
}
```

Also validate the VPC CIDR:

```hcl
variable "cidr_block" {
  description = "CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be valid CIDR notation."
  }
}
```

Why this matters: `project/modules/vpc/main.tf` builds maps by indexing
`var.availability_zones[index]`. If subnet CIDR lists are longer than the AZ
list, planning can fail with an index error. If they are shorter, you silently
get fewer subnets than expected.

## Exercise 3: Add a module output

Add this to `project/modules/vpc/outputs.tf`:

```hcl
output "internet_gateway_id" {
  description = "ID of the internet gateway attached to the VPC."
  value       = aws_internet_gateway.this.id
}
```

Expose it from the root module in `project/outputs.tf`:

```hcl
output "internet_gateway_id" {
  description = "Internet gateway ID from the VPC module."
  value       = module.vpc.internet_gateway_id
}
```

After apply:

```bash
terraform output internet_gateway_id
```

Expected output shape:

```text
"igw-0123456789abcdef0"
```

## Exercise 4: Create a service module input

Add a variable to `project/modules/ecs/variables.tf`:

```hcl
variable "environment_variables" {
  description = "Environment variables injected into the sample container."
  type        = map(string)
  default     = {}
}
```

Add the environment list to the task definition container in
`project/modules/ecs/main.tf`:

```hcl
container_definitions = jsonencode([
  {
    name      = "app"
    image     = var.container_image
    essential = true

    portMappings = [
      {
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
      }
    ]

    environment = [
      for key, value in var.environment_variables : {
        name  = key
        value = value
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.this.name
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "app"
      }
    }
  }
])
```

Pass values from the root module:

```hcl
module "ecs" {
  source = "./modules/ecs"

  name              = "${var.name}-${var.environment}"
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_groups.app_security_group_id
  container_port    = var.app_port
  desired_count     = 1
  create_service    = false

  environment_variables = {
    ENVIRONMENT = var.environment
    APP_PORT    = tostring(var.app_port)
  }

  tags = local.common_tags
}
```

The task definition JSON should contain:

```json
"environment": [
  {
    "name": "APP_PORT",
    "value": "8080"
  },
  {
    "name": "ENVIRONMENT",
    "value": "dev"
  }
]
```

Do not put secrets in this plain environment map. Use ECS `secrets` with Secrets
Manager or SSM Parameter Store for sensitive values.

## Exercise 5: Refactor with `moved` blocks

Example lab refactor: move a root-level S3 bucket into a child module.

Before:

```hcl
resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.name}-${var.environment}-artifacts"
  tags   = local.common_tags
}
```

After creating `modules/artifacts/main.tf`:

```hcl
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags
}
```

Root module call:

```hcl
module "artifacts" {
  source = "./modules/artifacts"

  bucket_name = "${var.name}-${var.environment}-artifacts"
  tags        = local.common_tags
}
```

Root `moved` block:

```hcl
moved {
  from = aws_s3_bucket.artifacts
  to   = module.artifacts.aws_s3_bucket.this
}
```

The successful plan should say the object moved. It should not show
`aws_s3_bucket.artifacts` destroyed and
`module.artifacts.aws_s3_bucket.this` created.

## Exercise 6: Version a module

In a separate repository:

```bash
mkdir terraform-aws-vpc
cp -R modules/vpc/* terraform-aws-vpc/
cd terraform-aws-vpc
git init
git add .
git commit -m "Initial VPC module"
git tag v1.0.0
git remote add origin https://example.com/your-org/terraform-aws-vpc.git
git push origin main --tags
```

Call the versioned module:

```hcl
module "vpc" {
  source = "git::https://example.com/your-org/terraform-aws-vpc.git?ref=v1.0.0"

  name                 = "${var.name}-${var.environment}"
  cidr_block           = var.vpc_cidr_block
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  tags                 = local.common_tags
}
```

Pinning protects production because later commits to the module repository do
not affect your root module until you intentionally change `ref`. Upgrade by
reviewing a plan for a new tag, such as `v1.1.0`.

## Exercise 7: Write module documentation

Example `project/modules/security-groups/README.md`:

````markdown
# security-groups module

## Purpose

Creates security groups for a three-tier application:

- Public ALB ingress on HTTP.
- Application tasks receiving traffic from the ALB.
- Database receiving PostgreSQL traffic from the application security group.

## Inputs

| Name | Description |
| --- | --- |
| `name` | Prefix used for security group names. |
| `vpc_id` | VPC where security groups are created. |
| `app_port` | Application port allowed from the ALB. |
| `db_port` | Database port allowed from the app security group. |
| `allowed_http_cidrs` | CIDR blocks allowed to reach the ALB on HTTP. |
| `tags` | Tags applied to security groups. |

## Outputs

| Name | Description |
| --- | --- |
| `alb_security_group_id` | Security group ID for a public load balancer. |
| `app_security_group_id` | Security group ID for application compute. |
| `database_security_group_id` | Security group ID for the database tier. |

## Security assumptions

- The ALB is the only public entry point.
- Application tasks accept traffic only from the ALB security group.
- The database accepts traffic only from the application security group.
- HTTP CIDRs should be narrowed for private or internal apps.

## Example usage

```hcl
module "security_groups" {
  source = "./modules/security-groups"

  name               = "module-course-dev"
  vpc_id             = module.vpc.vpc_id
  app_port           = 8080
  db_port            = 5432
  allowed_http_cidrs = ["203.0.113.0/24"]
  tags               = local.common_tags
}
```
````

Good module documentation lets a student or teammate use the interface without
reading every resource first.
