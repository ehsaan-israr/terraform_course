# Module 16 project — ECS + dflook Terraform Actions

Hands-on lab for [Module 16](../README.md). Copy this `project/` directory to
its own Git repository so `.github/workflows/` and `terraform/` are at the
root.

**Learning goals:** Terraform plan is the infrastructure diff; dflook posts that
plan on the PR and apply refuses `plan-changed`. Do not use `git diff` to decide
whether ECS changed.

ECS resources match [Module 13](../../13-aws-ecs/) with `ecs_desired_count = 0`
by default.

---

## Architecture

```text
Pull request  --> dflook/terraform-plan  --> PR comment (Terraform diff)
Merge to main --> dflook/terraform-apply --> apply if plan still matches
Schedule      --> dflook/terraform-check --> fail on drift (even if Git is clean)

AWS: ALB --> ECS Fargate (desired count 0 by default)
```

---

## File index

| Path | Purpose |
|------|---------|
| `terraform/*.tf` | ECS Fargate root: VPC, ALB, cluster, service, IAM, logs. |
| `terraform/versions.tf` | `required_version`, AWS provider, **partial** `backend "s3" {}`. |
| `terraform/terraform.tfvars.example` | Safe defaults used by CI (`var_file`). |
| `terraform/backend.hcl.example` | Local backend override template. |
| `.github/workflows/lint.yml` | `dflook/terraform-fmt-check`. |
| `.github/workflows/terraform-plan.yml` | PR plan + comment. **No `paths:` git filter.** |
| `.github/workflows/terraform-apply.yml` | Apply reviewed plan on `main`. |
| `.github/workflows/terraform-drift.yml` | Scheduled `terraform-check`. |
| `.github/workflows/terraform-pr-comment.yml` | `terraform plan` / `terraform apply` comments. |

---

## GitHub setup

1. Create Environment `dev`.
2. Secret `AWS_ROLE_ARN` — OIDC role for plan/apply.
3. Variables `TF_STATE_BUCKET` and `TF_LOCK_TABLE`.
4. Permissions: `id-token: write`, `contents: read`, `pull-requests: write`.
5. Branch protection on `main`: reviews, dismiss stale approvals, require the
   plan job, require up to date.

Workflows assume this directory is the repository root.

---

## Local loop

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
terraform fmt
terraform validate
```

`terraform plan` against the CI backend needs AWS credentials and a real
bucket/table from `backend.hcl.example`.

---

## Cost warning

Apply creates a billable ALB even when `ecs_desired_count = 0`. Prefer plan-only
in class. Destroy when finished.
