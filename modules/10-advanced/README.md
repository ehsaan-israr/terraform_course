# Module 10: Advanced Terraform

This module is about what happens after you can already write usable Terraform. You will learn how to model complicated inputs, generate infrastructure without copy-paste, bring existing resources under management, and refactor live code safely.

## Learning objectives

By the end of this module you should be able to:

- Explain how Terraform providers are built and when a custom provider is justified.
- Use advanced expressions to reshape maps, lists, sets, and object values.
- Model complex infrastructure inputs with precise types and validation.
- Use `jsonencode` to generate IAM policies, ECS task definitions, and other JSON APIs safely.
- Generate repeated nested blocks with `dynamic` blocks and `for_each`.
- Import existing resources using Terraform 1.5+ `import` blocks.
- Move resources between addresses using `moved` blocks instead of recreating them.
- Plan a staged migration from a monolithic Terraform root module to reusable modules.

## Provider development overview

Terraform Core does not directly know how to create an EC2 instance, S3 bucket, Cloudflare DNS record, or Datadog monitor. It delegates those actions to providers. A provider is a plugin process that implements Terraform's provider protocol and exposes:

- **Resources**: objects Terraform can create, update, read, and delete.
- **Data sources**: read-only lookups against an external API.
- **Provider configuration**: credentials, regions, endpoints, retry behavior, and feature flags.
- **Schemas**: typed attributes, nested blocks, validation rules, defaults, computed values, and sensitivity.

The common modern stack for provider development is Go, the Terraform Plugin Framework, provider acceptance tests, and generated documentation.

A minimal provider workflow looks like this:

1. Define provider-level schema such as endpoint and token.
2. Implement a client that talks to the target API.
3. Define resource schemas with required, optional, computed, and sensitive attributes.
4. Implement Create, Read, Update, Delete, and ImportState behavior.
5. Write unit tests for schema logic and acceptance tests for live behavior.
6. Publish documentation and provider binaries through the Terraform Registry or an internal mirror.

## When to build a custom provider

Build a custom provider when a platform has no maintained provider, the API is stable, many teams need the integration, and Terraform state should represent ownership. Avoid one when a simple CI step is enough, the API is unstable, or you cannot test lifecycle behavior.

A provider is production software. Treat it like one: semantic versioning, changelogs, compatibility tests, and deprecation windows matter.

## Advanced expressions

Terraform expressions are most powerful when you treat values as data transformations.

### For expressions

```hcl
locals {
  public_subnet_ids_by_az = {
    for subnet in aws_subnet.public : subnet.availability_zone => subnet.id
  }

  enabled_services = [
    for name, config in var.services : name
    if config.enabled
  ]
}
```

### Splat expressions

```hcl
output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
```

### Merge and defaults

```hcl
locals {
  default_tags = {
    ManagedBy = "terraform"
    Project   = var.project
  }

  tags = merge(local.default_tags, var.extra_tags)
}
```

### Try and can

Use `try` and `can` to normalize optional input shapes, not to hide design problems.

```hcl
locals {
  health_check_path = try(var.service.health_check.path, "/health")
  has_custom_domain = can(regex("\\.", var.domain_name))
}
```

## Complex data structures

Prefer expressive object types over loosely typed `any` values.

```hcl
variable "services" {
  description = "Microservices to deploy behind the platform load balancer."
  type = map(object({
    image         = string
    port          = number
    desired_count = number
    cpu           = number
    memory        = number
    public        = bool
    environment   = optional(map(string), {})
    secrets       = optional(map(string), {})
    health_check = optional(object({
      path                = string
      healthy_threshold   = number
      unhealthy_threshold = number
    }))
  }))

  validation {
    condition = alltrue([
      for _, service in var.services : service.port > 0 && service.port < 65536
    ])
    error_message = "Every service port must be between 1 and 65535."
  }
}
```

This structure gives callers freedom while preserving a clear contract.

## jsonencode

Many AWS APIs accept JSON: IAM policies, ECS task definitions, EventBridge patterns, dashboard bodies, and WAF rules. Do not hand-write JSON strings. Use native HCL values and `jsonencode`.

```hcl
resource "aws_iam_policy" "read_app_bucket" {
  name = "${var.name}-read-app-bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.app.arn,
          "${aws_s3_bucket.app.arn}/*"
        ]
      }
    ]
  })
}
```

Benefits: Terraform validates HCL first, references stay type-aware, escaping bugs disappear, and values are easier to compose.

## Dynamic infrastructure generation

Use `for_each` for repeated resources with stable keys.

```hcl
resource "aws_security_group_rule" "ingress" {
  for_each = var.ingress_rules

  type              = "ingress"
  security_group_id = aws_security_group.this.id
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = each.value.cidr_blocks
}
```

Use `dynamic` blocks for repeated nested blocks inside one resource.

```hcl
resource "aws_lb_listener_rule" "service" {
  for_each = var.services

  listener_arn = aws_lb_listener.https.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  dynamic "condition" {
    for_each = each.value.hostnames
    content {
      host_header {
        values = [condition.value]
      }
    }
  }
}
```

Keep generated infrastructure understandable. If a `for_each` expression requires a paragraph to explain, introduce a local value with a useful name.

## Import blocks in Terraform 1.5+

Terraform 1.5 introduced declarative import blocks. They let you commit import intent to version control.

```hcl
import {
  to = aws_s3_bucket.logs
  id = "company-prod-access-logs"
}
```

For resources inside modules:

```hcl
import {
  to = module.networking.aws_vpc.this
  id = "vpc-0123456789abcdef0"
}
```

A safe import workflow:

1. Write the resource block with desired arguments.
2. Add an `import` block with the remote object ID.
3. Run `terraform plan` and inspect drift.
4. Adjust configuration until the plan is no-op or intentionally changes only safe attributes.
5. Apply the import.
6. Remove the import block after the resource is in state, unless your team intentionally keeps import history in a migration branch.

Import does not magically generate ideal configuration. It only maps an existing remote object to a Terraform address.

## Moved blocks

A `moved` block tells Terraform that an object already tracked at one state address should now be tracked at another address. This is essential when refactoring root resources into modules.

### Before: monolithic root module

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = aws_vpc.main.id
}
```

### After: modular root module

```hcl
module "networking" {
  source     = "./modules/networking"
  cidr_block = "10.0.0.0/16"
}

module "web_security_group" {
  source = "./modules/security-group"
  vpc_id = module.networking.vpc_id
}
```

### Moved block

```hcl
moved {
  from = aws_vpc.main
  to   = module.networking.aws_vpc.this
}

moved {
  from = aws_security_group.web
  to   = module.web_security_group.aws_security_group.this
}
```

With these blocks, Terraform plans a state address move instead of destroy-and-create.

## Refactoring large codebases

Refactor in small, reversible steps:

1. Get a clean plan first.
2. Choose final module and resource names deliberately.
3. Move one boundary at a time: networking, security, compute, data, then observability.
4. Add `moved` blocks to preserve state lineage.
5. Run plans per workspace/environment.
6. Avoid combining refactor, upgrade, and behavior changes in one PR.
7. Document old address, new address, command history, and expected plan.
8. Remove old variables and outputs after consumers migrate.

## Interview questions

1. What is the difference between `count` and `for_each`, and why is `for_each` safer for long-lived resources?
2. When would you use a `dynamic` block instead of separate resources?
3. What problems does `jsonencode` solve?
4. How do Terraform 1.5 import blocks differ from the older `terraform import` CLI flow?
5. What does a `moved` block change: cloud infrastructure, Terraform state, or both?
6. How would you refactor a production VPC from a root module into a networking module?
7. What makes provider acceptance tests different from unit tests?
8. How do you design module input types for a platform used by many teams?

## Case study: monolith to modules migration

A startup has a single `main.tf` with VPCs, subnets, security groups, EC2 instances, RDS, IAM, and DNS. Every change is risky because unrelated resources appear in the same plan. The team wants reusable modules and environment-specific roots.

A practical migration plan:

- Week 1: capture clean plans for dev, staging, and prod. Fix unmanaged drift first.
- Week 2: create modules for networking and security groups without changing arguments.
- Week 3: add `moved` blocks and move VPC, subnet, route table, and security group resources.
- Week 4: move compute resources and add module outputs used by deployment pipelines.
- Week 5: split RDS and DNS with separate review owners.
- Week 6: remove dead variables and document the new operating model.

The migration succeeds because it separates state movement from design improvement. Optimization comes after the codebase is modular and plans are predictable.

## Mini project

In `project/`, you will inspect a monolithic Terraform file that mixes VPC, security group, and EC2 concerns. Then you will compare it to a modular refactor that preserves state with `moved` blocks.

Your tasks:

1. Read `project/before/monolith.tf` and identify ownership boundaries.
2. Review `project/after/modules/*` and map each resource to its new module.
3. Read `project/after/MIGRATION.md` and explain why no resources should be recreated.
4. Extend the compute module with one tag or variable while keeping the root module clean.
