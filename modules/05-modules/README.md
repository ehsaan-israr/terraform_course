# Module 05 - Terraform Modules

Modules are Terraform's unit of reuse and composition. A module is simply a
directory of Terraform files, but the engineering discipline around modules is
what makes infrastructure code maintainable at scale.

This module teaches how to design reusable modules, expose stable inputs and
outputs, compose modules into environments, version shared modules, test module
behavior, and decide when a module abstraction is worth creating.

## Learning objectives

By the end of this module you will be able to:

- Explain root modules, child modules, local modules, registry modules, and
  private modules.
- Design input variables and outputs that form a clean module interface.
- Compose modules without hiding important infrastructure behavior.
- Version modules safely and upgrade them deliberately.
- Use public and private registries.
- Test modules with validation, plans, examples, and automated tests.
- Recognize module anti-patterns in production codebases.

## 1. What is a module?

Every Terraform configuration is a module. The directory where you run
`terraform init`, `terraform plan`, and `terraform apply` is the root module.
Any module called from that root is a child module.

```text
root module
  |
  +-- module "network"
  |
  +-- module "database"
  |
  +-- module "service"
```

Module call example:

```hcl
module "network" {
  source = "./modules/vpc"

  name       = "payments-dev"
  cidr_block = "10.20.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]
}
```

The module at `./modules/vpc` can contain resources, variables, outputs, local
values, data sources, and nested module calls.

## 2. Why modules matter

Modules help teams:

- Reuse proven patterns.
- Reduce copy-paste infrastructure.
- Standardize tagging, naming, encryption, and security controls.
- Hide incidental repetition while exposing important decisions.
- Upgrade infrastructure patterns across many services.
- Create ownership boundaries between platform and application teams.

Modules can also cause harm when they hide too much, expose confusing inputs, or
become a dumping ground for unrelated resources. A good module makes the common
path easy while leaving enough control for real production differences.

## 3. Module anatomy

A common module layout:

```text
modules/
  vpc/
    versions.tf
    variables.tf
    main.tf
    outputs.tf
    README.md
```

Recommended file roles:

- `versions.tf`: required Terraform and provider versions.
- `variables.tf`: input interface and validation.
- `main.tf`: primary resources.
- `outputs.tf`: values consumers need.
- `README.md`: usage, assumptions, examples, and operational notes.

Terraform does not require these filenames. The convention helps humans.

## 4. Inputs: the module contract

Variables are the public API of a module. Design them carefully.

Good input:

```hcl
variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per availability zone."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) > 0
    error_message = "At least one private subnet CIDR block is required."
  }
}
```

Weak input:

```hcl
variable "settings" {
  type = any
}
```

Use precise types:

```hcl
variable "services" {
  type = map(object({
    cpu          = number
    memory       = number
    desired_count = number
    image        = string
  }))
}
```

Guidelines:

- Prefer explicit variables over large untyped maps.
- Provide defaults only when there is a safe common value.
- Validate assumptions close to the input.
- Include units in variable names or descriptions.
- Avoid exposing provider implementation details unless callers must control
  them.

## 5. Outputs: useful, not everything

Outputs are how modules share selected values with callers:

```hcl
output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = aws_subnet.private[*].id
}
```

Output values that consumers need:

- IDs for attaching resources.
- ARNs for IAM policies.
- DNS names for integrations.
- Security group IDs.

Do not output every attribute. That creates accidental coupling and makes module
internals harder to change.

## 6. Local, public, and private module sources

### Local source

```hcl
module "vpc" {
  source = "./modules/vpc"
}
```

Local modules are best for learning, monorepos, and tightly coupled examples.

### Git source

```hcl
module "vpc" {
  source = "git::https://github.com/example/terraform-aws-vpc.git?ref=v1.4.2"
}
```

Always pin Git modules with `?ref=`. Unpinned modules make builds
non-reproducible.

### Public registry

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "shared"
  cidr = "10.0.0.0/16"
}
```

The public registry is useful when a module is mature, widely used, and matches
your security/compliance needs. Review module source before production use.

### Private registry

Private registries are common in enterprises. They provide:

- Discoverability.
- Semantic versioning.
- Access control.
- Documentation.
- Consistent module source syntax.

Example:

```hcl
module "service" {
  source  = "app.terraform.io/acme/ecs-service/aws"
  version = "2.3.1"
}
```

## 7. Module composition

Composition means wiring small modules together in a root module:

```text
environment root
  |
  +-- vpc module
  |     +-- vpc
  |     +-- subnets
  |     +-- routes
  |
  +-- security-groups module
  |     +-- alb sg
  |     +-- app sg
  |     +-- db sg
  |
  +-- ecs module
  |     +-- cluster
  |     +-- task definition
  |     +-- service
  |
  +-- rds module
        +-- subnet group
        +-- db instance
```

Typical wiring:

```hcl
module "vpc" {
  source = "./modules/vpc"
}

module "security_groups" {
  source = "./modules/security-groups"

  vpc_id = module.vpc.vpc_id
}

module "rds" {
  source = "./modules/rds"

  subnet_ids          = module.vpc.private_subnet_ids
  app_security_group_id = module.security_groups.app_security_group_id
}
```

The root module decides the architecture. Child modules implement reusable
building blocks.

## 8. Module versioning

Treat shared modules like software packages.

Semantic versioning:

- `MAJOR`: breaking changes, such as renaming variables or replacing resources.
- `MINOR`: backward-compatible features.
- `PATCH`: bug fixes.

Safe upgrade process:

1. Read the changelog.
2. Upgrade one non-production environment.
3. Run `terraform init -upgrade`.
4. Review the plan for replacements.
5. Apply and observe.
6. Promote to production.

Pin versions:

```hcl
module "network" {
  source  = "app.terraform.io/acme/network/aws"
  version = "~> 3.2"
}
```

## 9. Designing stable modules

Good modules have:

- A narrow purpose.
- Clear ownership.
- Predictable names and tags.
- Input validation.
- Minimal required provider assumptions.
- Outputs that support composition.
- Examples that demonstrate common usage.
- Tests that prevent accidental breaking changes.

Module anti-patterns:

- One "everything" module for an entire company.
- Boolean explosions such as `create_alb`, `create_rds`, `create_dns`,
  `create_cache`, `create_queue`.
- Exposing every resource argument as a variable.
- Hiding critical architecture choices from callers.
- Changing resource addresses without `moved` blocks.
- Using `latest` or unpinned Git branches for production.

## 10. Testing modules

Testing happens at multiple layers:

### Static validation

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

### Example plans

Create an `examples/basic` root module and run:

```bash
terraform init
terraform plan
```

### Policy checks

Use policy tools to check requirements:

- S3 buckets must block public access.
- RDS must not be publicly accessible.
- Security groups must not allow unrestricted administrative ports.
- Required tags must be present.

### Integration tests

For higher-risk modules, create resources in a sandbox account and assert real
outputs. Common tools include Terratest, kitchen-terraform, and Terraform's
native testing framework.

Native test example shape:

```hcl
run "validates_vpc_plan" {
  command = plan

  assert {
    condition     = length(module.vpc.private_subnet_ids) == 2
    error_message = "Expected two private subnets."
  }
}
```

## 11. Module documentation

Every production module should document:

- Purpose and scope.
- Example usage.
- Required providers.
- Inputs and outputs.
- Resource naming rules.
- Security assumptions.
- Cost-impacting resources.
- Upgrade notes and known breaking changes.

Documentation is part of the module interface. If callers must read the source
to use the module safely, the module is not finished.

## 12. Hands-on exercises

1. Create a local `vpc` module and call it from a root module.
2. Add variable validation for CIDR lists.
3. Add outputs for `vpc_id`, `public_subnet_ids`, and `private_subnet_ids`.
4. Move a root resource into the module using a `moved` block.
5. Pin a public registry module and run `terraform init -upgrade`.
6. Write a README for one module that includes assumptions and examples.

## 13. Mini project

The project in `project/` composes four local modules:

- `vpc`: VPC, public/private subnets, internet gateway, NAT gateway, and routes.
- `security-groups`: ALB, app, and database security groups.
- `ecs`: ECS cluster, task definition skeleton, and service skeleton.
- `rds`: private DB subnet group and RDS instance.

The implementation is intentionally educational: it is structurally correct and
shows production patterns, but it includes comments where real teams would add
load balancers, deployment automation, observability, secrets, and service
discovery.

## 14. Interview Q&A

### Q1: What is the difference between a root module and a child module?

The root module is the directory where Terraform is executed. A child module is
called from another module using a `module` block.

### Q2: Why should module versions be pinned?

Pinned versions make plans reproducible. Without pinning, a module update can
change behavior unexpectedly during an unrelated deployment.

### Q3: What makes a good module interface?

A good interface exposes the decisions callers need to make, validates inputs,
uses precise types, and outputs only values required for composition.

### Q4: When should you not create a module?

Do not create a module when the abstraction hides only one resource with no
repeated pattern, when requirements are still changing rapidly, or when the
module would simply pass every resource argument through as a variable.

### Q5: How do you move resources into a module safely?

Add the module, keep resource arguments equivalent, and use `moved` blocks or
`terraform state mv` to map old addresses to new addresses. Then run a plan and
confirm Terraform does not propose replacements.

### Q6: How do private registries help enterprises?

They centralize module discovery, versioning, documentation, access control, and
governance. Platform teams can publish approved infrastructure patterns for
application teams.

### Q7: How do you test a module?

Run formatting and validation, plan example configurations, enforce policies,
and use integration tests for high-risk modules. Tests should protect the module
contract and prevent accidental destructive changes.

### Q8: What is module composition?

Composition is wiring focused modules together in a root module. For example,
the VPC module produces subnet IDs that the RDS and ECS modules consume.

## 15. Real-world case study: standardizing service infrastructure

A company has twenty application teams. Each team copied an old Terraform
example and customized it. After a year, the platform team finds inconsistent
tagging, public RDS instances, security groups open to the internet, and
different logging configurations.

The team creates a set of private modules:

- `network-baseline`
- `ecs-service`
- `private-rds`
- `service-observability`

They start with two pilot services instead of migrating all teams at once. The
modules enforce required tags, private subnets, encrypted storage, and CloudWatch
logs. The `ecs-service` module exposes only safe knobs: CPU, memory, image,
desired count, listener rule priority, and environment variables. It does not
allow callers to disable log encryption or place tasks in public subnets.

The rollout plan:

1. Publish modules as `v1.0.0`.
2. Provide examples for dev and prod.
3. Migrate pilot services with `moved` blocks where possible.
4. Add policy checks to prevent new copy-pasted infrastructure.
5. Track adoption by service.
6. Release `v1.1.0` with optional autoscaling after pilots succeed.

Outcome: teams deploy faster, security review time drops, and production plans
become easier to review because architecture is standardized. The platform team
keeps escape hatches for exceptional services, but those require explicit design
review rather than accidental drift from copied examples.

