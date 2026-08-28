# Module 07: Production Terraform Engineering

Production Terraform is less about writing a single resource correctly and more
about making change safe across teams, AWS accounts, regions, and time. This
module turns the Terraform skills from earlier modules into an operating model
for real AWS platforms.

## Learning objectives

By the end of this module you should be able to:

- Design a Terraform repository that separates reusable modules from live
  environment configuration.
- Explain the tradeoffs between workspace-based and directory-per-environment
  layouts.
- Plan AWS account separation for Dev, UAT/Staging, Prod, shared services, and
  security tooling.
- Apply naming and tagging standards consistently.
- Build CI/CD pipelines that run `fmt`, `validate`, `plan`, approvals, and
  guarded applies.
- Use GitOps practices for reviewable, auditable infrastructure changes.
- Describe blue/green infrastructure deployment patterns with Terraform.

## Production design principles

1. **One blast radius per state file.** State boundaries should match ownership
   and failure boundaries. A VPC, shared DNS zone, or production app stack should
   not be coupled to an unrelated experiment.
2. **Immutable review history.** Changes should be proposed through pull
   requests, reviewed, planned in CI, and applied by automation.
3. **Environment parity with intentional differences.** Dev, UAT, and Prod
   should use the same modules, but different inputs for scale, retention,
   alerting, and change windows.
4. **No secrets in Git or state when avoidable.** Use AWS Secrets Manager,
   SSM Parameter Store, OIDC federation, and sensitive outputs carefully.
5. **Small modules, boring interfaces.** A module should hide repeated resource
   wiring, not hide an entire company.

## Folder structures

The most common production layout separates `live/` configuration from reusable
`modules/`.

```text
repo/
|-- live/
|   |-- dev/
|   |   |-- backend.tf
|   |   |-- providers.tf
|   |   |-- main.tf
|   |   `-- terraform.tfvars
|   |-- staging/
|   `-- prod/
|-- modules/
|   |-- networking/
|   `-- app/
|-- .github/workflows/
|   `-- terraform.yml
`-- README.md
```

### Directory per environment

Directory-per-environment is the default recommendation for most teams because
it makes state, provider aliases, approvals, and path-based CI filters explicit.

```text
live/dev      -> dev account, small instances, relaxed deletion protection
live/staging  -> staging account, production-like inputs
live/prod     -> prod account, larger scale, stronger retention
```

Benefits:

- Easy to see which environment changed in a pull request.
- CI can run only the affected environment plan.
- Backend configuration is explicit per environment.
- Different AWS accounts and regions are straightforward.

Costs:

- Some repeated files.
- You must keep inputs aligned intentionally.

### Terraform workspaces

Workspaces can be useful for many identical short-lived stacks, but they are
not a strong production environment boundary by themselves.

```hcl
locals {
  env = terraform.workspace
}

module "app" {
  source      = "../modules/app"
  name_prefix = "payments-${local.env}"
  replicas    = local.env == "prod" ? 3 : 1
}
```

Workspace tradeoffs:

| Approach | Best for | Watch out for |
| --- | --- | --- |
| Directory per env | Dev/UAT/Prod, account separation, approvals | Slight duplication |
| Workspaces | Ephemeral review environments, identical sandboxes | Easy to apply to wrong workspace |
| Terragrunt or wrappers | Many accounts/regions with shared patterns | Extra tool and abstraction |

Production rule of thumb: use directories for long-lived environments and
workspaces only when the stacks are intentionally identical and disposable.

[Module 16](../16-aws-ecs-dflook/) is the exception used on purpose: one ECS
root, one account, env-wise numbers in `workspaces.tf`, and dflook's
`workspace:` input. It still refuses the `default` workspace. Use directories
again when accounts or approval boundaries differ.

## Environment separation: Dev, UAT, Prod

Environment separation is both technical and organizational.

### Dev

- Fast feedback.
- Lower cost and smaller capacity.
- Developers may have broader read access.
- Destructive changes can be acceptable if documented.

### UAT or Staging

- Production-like module versions.
- Production-like IAM boundaries.
- Representative data, never uncontrolled production data.
- Used for release validation and operational rehearsals.

### Prod

- Minimal human write access.
- Applies only through approved automation.
- Stronger retention, backups, monitoring, and encryption controls.
- Explicit change windows for high-risk changes.

## Multi-account AWS strategy

A production AWS organization usually separates accounts by workload,
environment, and security function.

```text
AWS Organization
|
|-- Security OU
|   |-- log-archive
|   `-- security-tooling
|
|-- Shared Services OU
|   |-- network-hub
|   `-- cicd
|
`-- Workloads OU
    |-- app-dev
    |-- app-uat
    `-- app-prod
```

Account topology with Terraform access:

```text
Developer
    |
    | pull request
    v
GitHub Actions
    |
    | OIDC assume-role
    v
CI/CD AWS Account
    |
    | sts:AssumeRole
    +------------------+-------------------+------------------+
    |                  |                   |                  |
    v                  v                   v                  v
 app-dev           app-uat              app-prod          security
 TerraformRole     TerraformRole        TerraformRole     AuditRole
```

Why separate accounts?

- IAM boundaries are stronger than naming conventions.
- Costs are easier to attribute.
- Security incidents have a smaller blast radius.
- Service quotas and noisy-neighbor effects are isolated.

## Multi-region design

Multi-region architecture should be justified by availability, latency,
regulatory, or disaster recovery requirements. Do not duplicate complexity
without an operational reason.

Common patterns:

- **Active/passive:** primary region serves traffic; secondary region is warm or
  cold standby.
- **Active/active:** multiple regions serve traffic at the same time, usually
  through Route 53 latency or failover routing.
- **Regional modules:** call the same module once per region with provider
  aliases.

Example provider aliases:

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

module "primary_app" {
  source = "../../modules/app"
}

module "dr_app" {
  source = "../../modules/app"

  providers = {
    aws = aws.west
  }
}
```

## Naming conventions

A predictable name helps humans and automation.

Recommended pattern:

```text
<company>-<workload>-<env>-<region>-<component>
```

Examples:

```text
acme-payments-prod-use1-vpc
acme-payments-staging-use1-app
acme-platform-dev-usw2-artifacts
```

Keep names:

- Lowercase.
- Short enough for AWS service limits.
- Free of secrets and customer data.
- Consistent with tags.

## Tagging standards

Tags are metadata for ownership, automation, cost allocation, and incident
response.

Minimum recommended tags:

```hcl
locals {
  common_tags = {
    Application = "payments"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "platform"
    CostCenter  = "eng-platform"
    Repository  = "github.com/example/payments-infra"
  }
}
```

Production tagging checklist:

- Enforce required tags in modules.
- Merge resource-specific tags with common tags.
- Use AWS Organizations tag policies for governance.
- Avoid putting secrets, emails with privacy concerns, or ticket descriptions in
  tag values.

## CI/CD pipeline for Terraform

Terraform automation should answer two questions:

1. What will change?
2. Who approved applying that change?

Pipeline flow:

```text
Pull request
    |
    v
terraform fmt -check
    |
    v
terraform init -backend=false
    |
    v
terraform validate
    |
    v
security scan / policy check
    |
    v
terraform plan
    |
    v
review plan output
    |
    v
merge to main
    |
    v
terraform apply with protected environment approval
```

### GitHub Actions: plan on pull request

```yaml
name: terraform

on:
  pull_request:
    paths:
      - "live/**"
      - "modules/**"

permissions:
  id-token: write
  contents: read
  pull-requests: write

jobs:
  plan:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, staging, prod]
    defaults:
      run:
        working-directory: live/${{ matrix.environment }}
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.8

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-terraform-plan
          aws-region: us-east-1

      - name: Terraform fmt
        run: terraform fmt -check -recursive ../..

      - name: Terraform init
        run: terraform init

      - name: Terraform validate
        run: terraform validate

      - name: Terraform plan
        run: terraform plan -input=false -out=tfplan
```

### GitHub Actions: apply on main

```yaml
name: terraform-apply

on:
  push:
    branches: [main]
    paths:
      - "live/**"
      - "modules/**"

permissions:
  id-token: write
  contents: read

jobs:
  apply:
    runs-on: ubuntu-latest
    environment: production
    defaults:
      run:
        working-directory: live/prod
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-terraform-apply
          aws-region: us-east-1

      - run: terraform init
      - run: terraform apply -input=false -auto-approve
```

In a real production system, use environment protection rules, branch
protection, CODEOWNERS, and separate plan/apply roles.

## GitOps operating model

GitOps means Git is the source of truth for desired infrastructure state.

Good GitOps habits:

- Every change starts as a pull request.
- CI posts a plan before merge.
- Reviewers inspect both code and plan.
- Applies are performed by automation, not laptops.
- Rollbacks are new commits, not hidden manual changes.
- Drift is detected on a schedule.

Anti-patterns:

- Running `terraform apply` from a personal machine against Prod.
- Sharing long-lived AWS keys in CI secrets.
- Reusing one state file for every environment.
- Approving plans without reading creates, updates, destroys, and replacements.

## Blue/green with Terraform

Blue/green deployment keeps two production-capable environments and moves
traffic between them.

```text
                 +----------------+
Users ---------->| Route 53 / ALB  |
                 +-------+--------+
                         |
              active_color = blue
                         |
        +----------------+----------------+
        |                                 |
        v                                 v
 +-------------+                   +-------------+
 | blue stack  |                   | green stack |
 | v1 live     |                   | v2 idle     |
 +-------------+                   +-------------+
```

Terraform can manage:

- The blue and green infrastructure stacks.
- The traffic routing weight or active target group.
- Deployment variables such as `active_color`.

Example:

```hcl
variable "active_color" {
  type    = string
  default = "blue"

  validation {
    condition     = contains(["blue", "green"], var.active_color)
    error_message = "active_color must be blue or green."
  }
}

locals {
  active_target_group_arn = var.active_color == "blue"
    ? aws_lb_target_group.blue.arn
    : aws_lb_target_group.green.arn
}
```

Operational cautions:

- Use health checks before shifting traffic.
- Keep database migrations backward compatible.
- Define rollback steps before starting.
- Monitor error rate, latency, and saturation during traffic shift.

## Interview Q&A

**Q: Why not use one Terraform state for all environments?**  
A: It creates a large blast radius. A lock, failed apply, or accidental destroy
can affect unrelated environments. Separate state by environment and component.

**Q: How do you prevent developers from applying directly to production?**  
A: Use IAM to deny direct writes, require OIDC-assumed CI roles, protect the
main branch, and require GitHub environment approvals for production applies.

**Q: When would you choose workspaces?**  
A: For many identical ephemeral environments, such as preview stacks. For
long-lived Dev/UAT/Prod, directories and separate backend config are clearer.

**Q: How do you structure modules?**  
A: Modules should represent reusable building blocks such as networking, app,
database, and observability. They expose variables for differences and outputs
for dependencies.

**Q: How do you manage multi-account providers?**  
A: Use AWS Organizations, IAM roles per account, and provider aliases or
separate environment directories configured to assume the correct role.

**Q: What should be reviewed in a Terraform plan?**  
A: Creates, updates, replacements, destroys, IAM policy changes, security group
rules, public exposure, encryption settings, tags, and unexpected provider
drift.

## Case study: Startup to enterprise repository evolution

### Stage 1: The startup repo

The first infrastructure repo starts simple:

```text
infra/
|-- main.tf
|-- variables.tf
`-- terraform.tfvars
```

One engineer runs Terraform locally. The company has one AWS account and one
production environment. This works until team size, customer expectations, and
compliance needs grow.

Problems appear:

- A developer accidentally applies an unfinished change.
- Prod and dev resources drift because they were copied manually.
- Secrets appear in `terraform.tfvars`.
- No one knows which commit created a resource.

### Stage 2: Environment directories

The team splits environments:

```text
live/dev
live/staging
live/prod
modules/networking
modules/app
```

Now Dev and Prod use the same modules with different inputs. Remote state uses
S3 and DynamoDB. Pull requests show which environment is affected.

### Stage 3: Multi-account and CI/CD

The company moves to AWS Organizations:

- `app-dev`
- `app-staging`
- `app-prod`
- `security`
- `shared-services`

GitHub Actions assumes a plan role for pull requests and an apply role after
merge. Production applies require manual approval from the platform team.

### Stage 4: Enterprise controls

The mature setup adds:

- CODEOWNERS for critical directories.
- Policy-as-code checks.
- Drift detection.
- Module versioning.
- Standard tags and cost allocation.
- Change management evidence from PRs and pipeline logs.

The important lesson: the repository evolved as risk increased. The team did
not start with maximum abstraction, but they introduced boundaries before the
old model became unsafe.

## Mini project: Enterprise Terraform repository

Build the repository skeleton in `project/` into a realistic enterprise
starting point.

### Requirements

1. Keep live environment configuration under:
   - `live/dev`
   - `live/staging`
   - `live/prod`
2. Keep reusable code under:
   - `modules/networking`
   - `modules/app`
3. Use AWS provider `~> 5.0`.
4. Configure remote state placeholders for each environment.
5. Add common tags in every environment.
6. Create a GitHub Actions workflow that:
   - Runs on pull requests for Terraform paths.
   - Runs `fmt`, `init`, `validate`, and `plan`.
   - Runs apply on `main`.
7. Include safe placeholders only. Do not commit real account IDs, secrets, or
   backend bucket names from a production company.

### Stretch goals

- Add a `CODEOWNERS` file.
- Add separate workflows for Dev, Staging, and Prod.
- Add drift detection on a schedule.
- Add policy checks before plan.
- Add a blue/green variable and traffic switch example to the app module.

