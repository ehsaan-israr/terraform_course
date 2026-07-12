# Branch Protection Setup for `main`

Configure these settings in **GitHub → Repository → Settings → Branches → Branch protection rules → Add rule** for branch name pattern `main`.

## Required Settings

### 1. Require a pull request before merging

- [x] Require approvals: **1** (use **2** for production teams)
- [x] Dismiss stale pull request approvals when new commits are pushed
- [x] Require review from Code Owners (if `CODEOWNERS` file exists)

### 2. Require status checks to pass before merging

Add these exact job names (match your workflow `name:` fields):

| Status check | Source workflow |
| --- | --- |
| `Terraform Plan` | Module 09 `terraform-plan.yml` or reusable plan job |
| `plan / Terraform plan (staging)` | `Deploy Staging` → reusable terraform plan |
| `Build and Push` | CI workflows from Module 07 |

- [x] Require branches to be up to date before merging

### 3. Restrict pushes

- [x] Do not allow bypassing the above settings (include administrators for training; exclude in real prod)
- [x] Restrict who can push to matching branches (optional: release managers only)

### 4. Additional recommendations

- [x] Require linear history (squash or rebase merges)
- [x] Require signed commits (optional, requires GPG or SSH signing setup)
- [ ] Allow force pushes: **disabled**
- [ ] Allow deletions: **disabled**

## Environment Protection (Settings → Environments)

### `staging`

- Required reviewers: **1**
- Deployment branches: `main` only

### `prod`

- Required reviewers: **2**
- Wait timer: **5 minutes** (optional)
- Deployment branches: `main` only
- Environment secret: `AWS_APPLY_ROLE_ARN` = prod apply role ARN

### `destroy-approval`

- Required reviewers: **2**
- Used only for destroy workflows

## Verification

1. Push directly to `main` — should be **rejected** if restrictions enabled.
2. Open PR with failing `terraform fmt` — merge button **disabled**.
3. Approve staging deploy — only listed reviewers receive notification.

## Screenshot Placeholders

<!-- Add screenshot: Branch protection rule overview -->
<!-- Add screenshot: Required status checks list -->
<!-- Add screenshot: Environment reviewers for prod -->
