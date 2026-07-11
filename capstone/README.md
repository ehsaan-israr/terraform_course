# Final Capstone: Production AWS Platform with Terraform

You will design and scaffold a production-ready platform using Terraform modules, remote state, multi-environment roots, CI/CD, security scanning, cost awareness, monitoring, backup, and disaster recovery documentation.

## Target architecture

```text
Internet
   |
Route53
   |
CloudFront + WAF
   |
Application Load Balancer
   |
ECS Fargate Services
   |
Microservices
   |--------------+----------------+----------------+
                  |                |                |
                 RDS             Redis             S3
                  |                |                |
          Secrets Manager     CloudWatch       Backup/DR
```

## Learning objectives

- Compose a platform from reusable Terraform modules.
- Keep dev, staging, and prod isolated through separate root modules and backend configs.
- Use an ECS Fargate + ALB pattern for containerized workloads.
- Add RDS, Redis, S3, CloudFront, Route53, WAF, Secrets Manager, and CloudWatch.
- Document production readiness, operations, backup, and disaster recovery.
- Build CI workflows for plan/apply, security scanning, and optional cost review.

## Requirements

Your solution must include:

- Multi-environment layout for dev, staging, and prod.
- Remote state backend configuration examples.
- Reusable modules with meaningful variables, resources, and outputs.
- CI/CD workflow for formatting, initialization, validation, plan, and gated apply.
- Security scanning workflow.
- Optional Infracost step for pull request cost awareness.
- Module and architecture documentation.
- Monitoring and alerting primitives.
- Backup and disaster recovery guidance.
- Production readiness checklist.

## Repository layout

```text
capstone/
  environments/
    dev/
    staging/
    prod/
  modules/
    cache/
    cdn/
    compute-ecs/
    database/
    dns/
    monitoring/
    networking/
    security/
    storage/
  docs/
    ARCHITECTURE.md
    PRODUCTION_CHECKLIST.md
    RUNBOOK.md
  .github/workflows/
    plan-apply.yml
    security-scan.yml
```

## Module-by-module walkthrough

### `modules/networking`

Creates the network foundation: VPC, public subnets, private subnets, internet
gateway, route tables, and an optional NAT gateway for private-subnet egress.
The environment roots pass a different VPC CIDR per environment so state,
networking, and address ranges stay isolated.

### `modules/security`

Creates a KMS key, Secrets Manager secret placeholders, and an AWS WAFv2 web ACL
with AWS managed common rules. The ECS task definition receives secret ARNs from
this module rather than hard-coding secret values.

### `modules/storage`

Creates the private assets S3 bucket with versioning, server-side encryption,
and public access blocking. Dev sets `force_destroy = true` for cleanup-friendly
labs; staging and prod keep it false.

### `modules/compute-ecs`

Creates the ECS cluster, CloudWatch log group, public Application Load Balancer,
target group, listener, ECS task execution role, task role, Fargate task
definition, and Fargate service. The service runs in private subnets and accepts
traffic only from the ALB security group.

### `modules/database`

Creates an RDS PostgreSQL instance in private subnets, a DB subnet group, and a
database security group that allows PostgreSQL only from the ECS service
security group. Environment roots tune instance class, Multi-AZ, backup
retention, and deletion protection.

### `modules/cache`

Creates an ElastiCache Redis replication group in private subnets, a subnet
group, and a Redis security group that accepts traffic only from ECS tasks.
Staging and prod use more than one node for higher availability.

### `modules/cdn`

Creates a CloudFront distribution in front of the ALB. Viewer traffic is
redirected to HTTPS, WAF is attached at the edge, and an ACM certificate can be
supplied when using a custom domain.

### `modules/dns`

Creates Route53 records when a hosted zone and domain name are provided. The
sample roots create a CNAME from the application domain to the CloudFront
distribution domain.

### `modules/monitoring`

Creates an SNS alert topic, optional email subscription, CloudWatch alarms for
ALB 5xx, target 5xx, and ECS CPU, plus a dashboard for service health. A real
production extension should add application-specific SLOs and paging routes.

## Environment differences

| Setting | dev | staging | prod |
| --- | --- | --- | --- |
| Root path | `environments/dev` | `environments/staging` | `environments/prod` |
| State key | `capstone/dev/terraform.tfstate` | `capstone/staging/terraform.tfstate` | `capstone/prod/terraform.tfstate` |
| VPC CIDR | `10.10.0.0/16` | `10.20.0.0/16` | `10.30.0.0/16` |
| ECS desired count | `1` | `2` | `3` |
| RDS class | `db.t4g.micro` | `db.t4g.small` | `db.t4g.medium` |
| RDS Multi-AZ | `false` | `true` | `true` |
| RDS backups | `3` days | `7` days | `14` days |
| RDS deletion protection | `false` | `false` | `true` |
| Redis nodes | `1` | `2` | `2` |
| S3 force destroy | `true` | `false` | `false` |

All three environments use the same module composition. The differences are
capacity, retention, deletion safety, and blast-radius isolation.

## Step-by-step local apply guide

> Cost warning: this capstone creates billable AWS resources, including NAT
> gateway, ALB, ECS Fargate, RDS, ElastiCache, CloudFront, WAF, CloudWatch, and
> possibly Route53/ACM-related resources. Apply only in a sandbox account with a
> budget alert. Destroy non-production environments when finished.

1. Choose an environment:

   ```bash
   cd capstone/environments/dev
   ```

2. Review and replace backend settings in `backend.hcl`:

   ```hcl
   bucket         = "example-company-terraform-state"
   key            = "capstone/dev/terraform.tfstate"
   region         = "us-east-1"
   dynamodb_table = "example-company-terraform-locks"
   encrypt        = true
   ```

   Use a real encrypted, versioned state bucket and lock table created outside
   this root.

3. Copy example variables and replace placeholders:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Set at least:

   ```hcl
   container_image    = "your-account-id.dkr.ecr.us-east-1.amazonaws.com/app:tag"
   database_password  = "replace-with-lab-secret"
   redis_auth_token   = null
   route53_zone_id    = ""
   domain_name        = ""
   certificate_arn    = ""
   alarm_email        = "you@example.com"
   ```

   Do not commit `terraform.tfvars`. Prefer CI/CD or a secret manager for
   production values.

4. Format and initialize:

   ```bash
   terraform fmt -recursive ../..
   terraform init -backend-config=backend.hcl
   ```

5. Validate and plan:

   ```bash
   terraform validate
   terraform plan -input=false -out=tfplan
   ```

   Read the plan for creates, replacements (`-/+`), public access, and
   environment-specific settings before applying.

6. Apply only after confirming cost and blast radius:

   ```bash
   terraform apply tfplan
   ```

7. Smoke test:

   ```bash
   terraform output
   ```

   Check the CloudFront domain or ALB DNS name, ECS service events, target group
   health, and CloudWatch alarms.

8. Destroy lab environments when finished:

   ```bash
   terraform destroy
   ```

   Production should not be destroyed from a workstation. Use protected CI/CD
   workflows and change approvals.

## CI/CD workflow

The capstone includes GitHub Actions workflow examples under
[`capstone/.github/workflows`](.github/workflows):

- [`plan-apply.yml`](.github/workflows/plan-apply.yml) runs `terraform fmt`,
  `terraform init`, `terraform validate`, and `terraform plan` for dev, staging,
  and prod on pull requests that touch `capstone/**`. It also includes a manual
  `workflow_dispatch` apply job scoped to the selected environment.
- [`security-scan.yml`](.github/workflows/security-scan.yml) runs Trivy IaC
  scanning for high and critical findings and includes an optional Infracost
  comment step when `INFRACOST_API_KEY` is configured.

Production teams should add OIDC role assumptions, protected environments,
manual approvals for prod, non-example variable injection, artifacted plan
files, and separate apply permissions.

## Production readiness

Use the documents in [`docs/`](docs/) before treating this as production:

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) explains request flow, module
  responsibilities, security patterns, costs, and backup/DR concepts.
- [`docs/RUNBOOK.md`](docs/RUNBOOK.md) gives operational checks, deployment
  steps, incident response prompts, and break-glass guidance.
- [`docs/PRODUCTION_CHECKLIST.md`](docs/PRODUCTION_CHECKLIST.md) lists readiness
  checks for Terraform workflow, security, reliability, backup/DR, cost, and
  documentation.

Important gaps to close for real production include least-privilege task role
policies, autoscaling, HTTPS from CloudFront to the origin, access logging,
centralized secrets rotation, tested restore procedures, and business-approved
RTO/RPO.

## Interview-style walkthrough questions

Use these prompts to practice presenting the capstone:

1. Walk through a user request from Route53 to CloudFront, WAF, ALB, ECS, RDS,
   Redis, S3, and CloudWatch.
2. Why are ECS tasks, RDS, and Redis placed in private subnets?
3. Which modules own security boundaries, and how are security group references
   passed between modules?
4. How does the design keep dev, staging, and prod isolated?
5. What production settings are stricter in prod than in dev?
6. What values are sensitive, where do they enter Terraform, and where can they
   still appear in state?
7. How would you review a Terraform plan for accidental replacement or data
   loss?
8. What does the CI workflow do on pull requests, and what extra controls would
   you add before a production apply?
9. Which resources drive the largest cost, and how would you reduce non-prod
   spend?
10. How would you restore the database or recover from a bad deploy?

## Acceptance checklist

- [ ] `terraform fmt -recursive` passes for `capstone/`.
- [ ] Each module has `variables.tf`, `main.tf`, and `outputs.tf`.
- [ ] Environment roots call the modules consistently.
- [ ] Backend settings are unique per environment and use encrypted remote
      state with locking.
- [ ] Sensitive values are variables, CI secrets, or Secrets Manager references,
      not hard-coded in committed files.
- [ ] Dev, staging, and prod have separate CIDRs and state keys.
- [ ] Production settings are stricter than dev where relevant.
- [ ] The plan has been reviewed for replacements, destroys, public exposure,
      and cost impact.
- [ ] CI runs formatting, initialization, validation, plan, and security scans.
- [ ] Production applies require approval through protected workflow controls.
- [ ] Monitoring alarms notify an owned channel.
- [ ] Backup and restore procedures are documented and tested.
- [ ] Documentation explains architecture, runbooks, and readiness checks.

## Suggested delivery plan

1. Read `docs/ARCHITECTURE.md`.
2. Review every module under `modules/`.
3. Pick one environment under `environments/dev` and inspect the module composition.
4. Wire real backend values in `backend.hcl`.
5. Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust values.
6. Run `terraform init -backend-config=backend.hcl`.
7. Run `terraform plan`.
8. Promote the same pattern to staging and prod with stricter variables.
