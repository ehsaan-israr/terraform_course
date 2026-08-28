# Module 16 project — ECS + dflook + Terraform workspaces

Hands-on lab for [Module 16](../README.md). Copy this `project/` directory to
its own Git repository so `.github/workflows/` and `terraform/` are at the
root.

**Learning goals:** Terraform plan is the infrastructure diff; dflook posts that
plan on the PR and apply refuses `plan-changed`. Environments are **Terraform
workspaces** (`dev` / `staging` / `prod`), not tfvars files. Do not use
`git diff` to decide whether ECS changed.

---

## Architecture

```text
Pull request  --> matrix workspace=dev|staging|prod
              --> dflook/terraform-new-workspace
              --> dflook/terraform-plan  label=ecs-<workspace>
              --> PR comment per workspace (Terraform diff)

Merge to main --> same matrix, terraform-apply if the comment still matches
Schedule      --> terraform-check per workspace (even if Git is clean)

AWS per workspace: ALB --> ECS Fargate
  dev/staging: desired count 0, public tasks, no NAT
  prod:        desired count 1, private tasks + NAT
```

---

## File index

| Path | Purpose |
|------|---------|
| `terraform/*.tf` | One ECS Fargate root: VPC, ALB, cluster, service, IAM, logs. |
| `terraform/workspaces.tf` | Env map keyed by `terraform.workspace`. **No tfvars.** |
| `terraform/versions.tf` | `required_version`, AWS provider, **partial** `backend "s3" {}`. |
| `terraform/backend.hcl.example` | Local backend override. **One** state key for all workspaces. |
| `.github/workflows/lint.yml` | `dflook/terraform-fmt-check`. |
| `.github/workflows/terraform-plan.yml` | PR plan matrix. **No `paths:` git filter. No `var_file`.** |
| `.github/workflows/terraform-apply.yml` | Apply reviewed plan per workspace on `main`. |
| `.github/workflows/terraform-drift.yml` | Scheduled `terraform-check` per workspace. |
| `.github/workflows/terraform-pr-comment.yml` | `terraform plan` all workspaces; `terraform apply <name>` one. |

---

## GitHub setup

1. Create GitHub Environments named `dev`, `staging`, and `prod` (same strings
   as the Terraform workspaces).
2. Secret `AWS_ROLE_ARN` on each environment — OIDC role for that workspace.
   Prod can require reviewers. Trust `repo:ORG/REPO:environment:prod` for prod.
3. Variables `TF_STATE_BUCKET` and `TF_LOCK_TABLE` on each environment (same
   bucket; workspaces isolate state under `env:/<workspace>/...`).
4. Permissions: `id-token: write`, `contents: read`, `pull-requests: write`.
5. Branch protection on `main`: reviews, dismiss stale approvals, require the
   plan jobs, require up to date.

Workflows assume this directory is the repository root.

---

## Local loop

```bash
cd terraform
terraform init -backend=false
terraform workspace new dev        # once
terraform workspace select dev
terraform fmt
terraform validate
# terraform plan   # needs AWS + backend.hcl; the default workspace is rejected
```

There is no `terraform.tfvars`. Change CIDR or desired count in `workspaces.tf`.
`terraform plan` against the CI backend needs AWS credentials and a real
bucket/table from `backend.hcl.example`. Keep the backend **key** as
`ecs-dflook/terraform.tfstate` — do not add `/dev`.

---

## Cost warning

Apply creates a billable ALB even when desired count is 0. `prod` also creates
a NAT gateway. Prefer plan-only in class. Destroy when finished. Never apply
the `default` workspace.
