# Module 10 Solution — Line-by-Line Explanation

## IAM Split (`terraform/iam/`)

### `plan-role.tf`

- **`terraform_plan` role** — Assumed during PR plan jobs.
- **`plan_policy`** — Only `s3:GetObject`, `s3:ListBucket` on state bucket; `dynamodb:GetItem` for lock reads; `Describe*` and `List*` APIs for planning. **No** `RunInstances`, `CreateCluster`, or `PutObject` on state.

### `apply-roles.tf`

- **`terraform_apply` role** — One per environment (`-dev`, `-staging`, `-prod` in role name).
- **State RW** — Scoped to `s3://bucket/${environment}/*` prefix so prod role cannot write dev state.
- **`ManageTaggedResources`** — Write APIs allowed only when `aws:RequestTag/Environment` matches `var.environment`.
- **`CreateWithTag`** — Create APIs require the same tag condition at request time.
- **`PassRoleToEKS`** — Limits `iam:PassRole` to EKS service only.

### `ecr-role.tf`

- **`ecr:GetAuthorizationToken`** — Required on `*` for Docker login.
- **Push actions** — Scoped to `aws_ecr_repository.app.arn` only.

## Environment Config (`config/*.tfvars`)

Each file sets `environment`, `node_count`, and `instance_types` differently so you can verify the correct file was applied via SSM parameters in `main.tf`.

## Reusable Terraform Workflow

| Input | Purpose |
| --- | --- |
| `environment` | Selects GitHub Environment (approval rules) |
| `terraform_action` | `plan` or `apply` — single workflow, two modes |
| `tfvars_file` | Path to env-specific variables |
| `aws_role_arn` | Plan or apply role passed by caller |
| `working_directory` | Terraform root path |

**Backend key** = `${{ inputs.environment }}/terraform.tfstate` — isolates state per environment.

**`environment: ${{ inputs.environment }}`** — Activates GitHub Environment protection and secrets.

## Reusable Docker Build

- Uses `amazon-ecr-login@v2` after OIDC credentials.
- Tags images with `${{ github.sha }}` and `latest`.
- `ecr_repository` input must match Terraform-created repo name pattern.

## Entry Workflows

### `deploy-dev.yml`

- Triggers on `develop` push — fast iteration without prod gates.
- `plan` then `apply` then `docker` — sequential `needs:` chain.

### `deploy-staging.yml`

- Triggers on `main` push — staging tracks production branch.
- Uses `environment: staging` via reusable workflow → **1 reviewer** required before apply.

### `deploy-prod.yml`

- **`workflow_dispatch` only** — no automatic prod applies.
- Validates `confirm == deploy-prod` and `github.ref == refs/heads/main`.
- Plan → apply → docker with `environment: prod` → **2 reviewers**.

## GitHub Secrets Matrix

| Secret | Scope | Value |
| --- | --- | --- |
| `AWS_PLAN_ROLE_ARN` | Repository | `terraform_plan` role |
| `AWS_APPLY_ROLE_ARN` | Per environment | Matching `terraform_apply` role |
| `ECR_PUSH_ROLE_ARN` | Per environment | `ecr_push` role |
| `TF_STATE_BUCKET` | Repository | State bucket name |
| `TF_LOCK_TABLE` | Repository | DynamoDB table |

Use **environment secrets** to override `AWS_APPLY_ROLE_ARN` per dev/staging/prod.

## `docs/branch-protection.md`

Documents UI-only settings that cannot live in repo YAML. Status check names must **exactly match** job names in Actions logs.
