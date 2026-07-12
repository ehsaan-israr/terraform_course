# Module 10 Exercise: Production Hardening

## Objective

Refactor your Module 09 pipeline into a **production-grade** setup with least-privilege IAM, per-environment configuration, GitHub Environments with approval gates, reusable workflows, and documented branch protection.

## Requirements

1. **IAM least privilege**
   - Separate roles: `terraform-plan`, `terraform-apply` (per environment or scoped policies).
   - ECR push role limited to specific repository ARNs.
   - No `iam:*` or `ec2:*` on `*` for the plan role.

2. **Environment-specific Terraform**
   - `config/dev.tfvars`, `config/staging.tfvars`, `config/prod.tfvars`.
   - Separate remote state keys per environment in the same S3 bucket.
   - Shared DynamoDB lock table.

3. **Reusable workflows**
   - `reusable-terraform.yml` — accepts inputs: `environment`, `terraform_action` (plan|apply), `tfvars_file`, `aws_role_arn`.
   - `reusable-docker-build.yml` — build, tag with SHA, push to ECR.

4. **Entry workflows**
   - `deploy-dev.yml` — auto deploy on push to `develop` (or manual).
   - `deploy-staging.yml` — deploy on merge to `main` with staging environment approval.
   - `deploy-prod.yml` — manual only from `main` with prod environment (2 reviewers).

5. **Branch protection documentation**
   - Document required settings for `main` in `docs/branch-protection.md` (UI steps).

6. **Secrets**
   - Repository: `AWS_PLAN_ROLE_ARN`, `TF_STATE_BUCKET`, `TF_LOCK_TABLE`.
   - Per environment: `AWS_APPLY_ROLE_ARN`, optional `TF_VAR_*` overrides.

## Constraints

- Region: `us-east-1`.
- Pin all GitHub Actions and Terraform versions.
- Prod deploy must not run from feature branches.
- Do not duplicate Terraform steps across three entry workflows — use `workflow_call`.
- Plan role must not be able to create EC2 or EKS resources (verify with IAM policy).

## Tasks

### Task 1: IAM Roles and Policies

Create Terraform for plan, apply (dev/staging/prod), and ECR push roles with OIDC trust for your repository.

### Task 2: Environment Tfvars

Define at minimum: `environment`, `instance_types`, `node_count` (or similar) with different values per env.

### Task 3: Reusable Terraform Workflow

Implement callable workflow with matrix or inputs for environment; write backend config with env-specific state key.

### Task 4: Reusable Docker Build Workflow

Build from `app/` or `docker/`, tag `:${{ github.sha }}`, push to ECR using OIDC.

### Task 5: Entry Workflows

Wire dev/staging/prod entry points to reusable workflows with correct `environment:` and triggers.

### Task 6: Branch Protection Guide

Write `docs/branch-protection.md` with screenshots placeholders and exact required check names matching your workflows.

## Expected Deliverables

| Deliverable | Path |
| --- | --- |
| IAM Terraform | `terraform/iam/*.tf` |
| Environment configs | `config/*.tfvars` |
| Reusable workflows | `.github/workflows/reusable-*.yml` |
| Deploy workflows | `.github/workflows/deploy-*.yml` |
| Branch protection doc | `docs/branch-protection.md` |
| Outputs | Role ARNs per environment |

## Validation Checklist

- [ ] Plan workflow assumes plan role and completes `terraform plan` successfully.
- [ ] Plan role denied `ec2:RunInstances` in IAM simulator (or equivalent test).
- [ ] Dev apply uses dev state key and dev apply role.
- [ ] Staging job waits for reviewer approval before apply.
- [ ] Prod job requires two reviewers (configure in GitHub UI).
- [ ] Reusable workflows are called, not copy-pasted.
- [ ] Docker image pushed to ECR with commit SHA tag.
- [ ] Branch protection doc lists exact status check names from your workflows.
- [ ] No long-lived AWS access keys in the repository.
- [ ] All three tfvars files produce distinct resource naming or tags.
