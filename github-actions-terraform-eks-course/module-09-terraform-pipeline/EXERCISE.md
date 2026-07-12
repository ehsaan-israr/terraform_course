# Module 09 Exercise: Terraform CI/CD Pipeline

## Objective

Build a GitHub Actions pipeline that runs Terraform **plan** on pull requests and **apply** on merge to `main`, using an S3 remote backend, DynamoDB state locking, and OIDC authentication to AWS—without storing long-lived AWS access keys in GitHub.

## Requirements

1. **Remote backend**
   - S3 bucket with versioning and server-side encryption enabled.
   - DynamoDB table for state locking.
   - Partial backend configuration via `backend.hcl` (commit an example file, not production values with secrets).

2. **OIDC IAM role**
   - GitHub OIDC provider in AWS IAM.
   - IAM role assumable only by your repository's workflows on `main` (and optionally PR refs for plan).
   - Policies granting least privilege for Terraform state access and infrastructure management in `us-east-1`.

3. **Workflows**
   - `terraform-plan.yml` — runs on pull requests; executes `terraform init`, `fmt -check`, `validate`, and `plan`.
   - `terraform-apply.yml` — runs on push to `main` and supports `workflow_dispatch`.
   - `terraform-destroy.yml` — **manual only** (`workflow_dispatch`); requires a confirmation input.

4. **Terraform code**
   - Manage at minimum: backend bootstrap resources (or document one-time setup), and a small infrastructure footprint (e.g. S3, IAM, or tags-only resources from prior modules).
   - Use Terraform `>= 1.5` and AWS provider `~> 5.0`.
   - Region: `us-east-1`.

5. **Secrets**
   - Store `AWS_ROLE_ARN` and backend identifiers in GitHub Secrets.
   - Do not commit AWS access keys or sensitive `backend.hcl` values.

## Constraints

- Do **not** use long-lived `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` in workflows.
- Apply and destroy must **not** run on every pull request.
- Destroy must require explicit human confirmation (input or environment).
- All workflows must pin action versions (e.g. `@v4`) and Terraform version.
- Use `working-directory` if Terraform lives in a subdirectory.

## Tasks

### Task 1: Bootstrap Backend

Create Terraform configuration for the S3 bucket and DynamoDB lock table. Apply once locally. Document bucket and table names.

### Task 2: Configure OIDC

Add IAM OIDC provider and a role for GitHub Actions. Scope trust to your GitHub org/repo. Attach policies for state and resource management.

### Task 3: Implement Plan Workflow

On pull requests targeting `main`:

- Checkout code.
- Assume AWS role via OIDC.
- Initialize Terraform with `backend-config=backend.hcl`.
- Run `fmt -check`, `validate`, `plan -out=tfplan`.
- Upload plan artifact or post summary to the PR.

### Task 4: Implement Apply Workflow

On push to `main`:

- Same auth and init steps.
- Run `terraform apply -auto-approve` (or apply saved plan).
- Export key outputs in the workflow summary.

### Task 5: Implement Destroy Workflow

Manual trigger only:

- Require typed confirmation (e.g. input `confirm_destroy` must equal `destroy`).
- Run `terraform destroy -auto-approve` only when confirmed.

### Task 6: Document Setup

Add a short section in your repo README listing required GitHub Secrets and one-time bootstrap steps.

## Expected Deliverables

| Deliverable | Description |
| --- | --- |
| `terraform/` | IaC including backend bootstrap and main resources |
| `backend.hcl.example` | Example backend config |
| `.github/workflows/terraform-plan.yml` | PR plan pipeline |
| `.github/workflows/terraform-apply.yml` | Apply pipeline |
| `.github/workflows/terraform-destroy.yml` | Manual destroy pipeline |
| `iam-oidc.tf` (or equivalent) | OIDC provider and role |
| Documentation | Secrets list and bootstrap instructions |

## Validation Checklist

- [ ] S3 bucket has versioning and encryption enabled.
- [ ] DynamoDB table exists with lock key attribute `LockID`.
- [ ] No AWS access keys in repository or workflow files.
- [ ] OIDC trust policy matches your GitHub repository.
- [ ] Pull request triggers plan workflow successfully.
- [ ] Merging to `main` triggers apply workflow successfully.
- [ ] Destroy workflow only runs via manual dispatch with confirmation.
- [ ] State file appears in S3 after successful apply.
- [ ] Concurrent applies are prevented by state locking.
- [ ] `terraform fmt -check` fails the workflow when formatting is wrong.
