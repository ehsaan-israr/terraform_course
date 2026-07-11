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

## Acceptance criteria

- `terraform fmt -recursive` passes.
- Each module has `variables.tf`, `main.tf`, and `outputs.tf`.
- Environment roots call the modules consistently.
- Sensitive values are variables or Secrets Manager references, not hard-coded secrets.
- Production settings are stricter than dev where relevant.
- Documentation explains architecture, runbooks, and readiness checks.

## Suggested delivery plan

1. Read `docs/ARCHITECTURE.md`.
2. Review every module under `modules/`.
3. Pick one environment under `environments/dev` and inspect the module composition.
4. Wire real backend values in `backend.hcl`.
5. Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust values.
6. Run `terraform init -backend-config=backend.hcl`.
7. Run `terraform plan`.
8. Promote the same pattern to staging and prod with stricter variables.
