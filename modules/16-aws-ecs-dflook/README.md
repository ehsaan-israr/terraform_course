# Module 16 - AWS ECS + dflook + Terraform workspaces

This module is a dedicated ECS delivery lab. Module 13 taught the **resources**.
This module teaches how those resources move through GitHub without treating
`git diff` as the infrastructure diff.

**Tool:** [dflook/terraform-github-actions](https://github.com/dflook/terraform-github-actions)
(`terraform-plan`, `terraform-apply`, `terraform-check`, `terraform-fmt-check`).

**Prerequisites:** [Module 13 AWS ECS](../13-aws-ecs/), Module 04 (remote state),
Module 07 (plan in PR). Optional contrast: Module 14 `project-cicd/` path filters.

## Learning objectives

By the end of this module you will be able to:

- Explain why `git diff` is the wrong signal for “did AWS change?”
- Use `dflook/terraform-plan` so **Terraform** computes the diff (config vs state
  vs AWS APIs) and posts it on the pull request.
- Apply only a reviewed plan with `dflook/terraform-apply` (fail on
  `plan-changed`).
- Detect drift on a schedule with `dflook/terraform-check`.
- Authenticate GitHub Actions to AWS with OIDC, not static keys.
- Select **dev / staging / prod** with Terraform workspaces (`terraform.workspace`), not tfvars.
- Pass `workspace:` into dflook so each environment has its own state and plan comment.
- Contrast this with shell `terraform plan` (Module 07) and path-filtered
  monorepo CI (Module 14).

## 1. Git diff vs Terraform plan

`git diff` answers: *which files in this repository changed?*

`terraform plan` answers: *what would AWS look like if we applied this
configuration to this state?*

Those are different questions.

```text
git diff
  |-- README.md changed          --> Git: yes. Terraform: often "No changes."
  |-- no .tf files changed       --> Git: empty.
        |-- someone edited a
        |   security group in
        |   the console          --> Terraform: update in-place
        |-- AMI data source
        |   resolved a new id    --> Terraform: replace instance
        |-- provider upgrade     --> Terraform: maybe replace

The infrastructure diff lives in the plan, not in Git.
```

Path filters (`on.pull_request.paths`) are a **CI cost** optimization. They must
not be the source of truth for ECS/ALB/IAM changes. This lab’s plan and apply
workflows intentionally **omit** `paths:` filters so every PR gets a real
Terraform plan. A no-op plan is still useful: it proves Terraform agrees with
state.

dflook makes that plan visible and **binding**:

```text
Pull request (matrix: workspace = dev, staging, prod)
  --> dflook/terraform-new-workspace
  --> dflook/terraform-plan  workspace=<name>  label=ecs-<name>
        --> terraform init + plan against S3 state for THAT workspace
        --> PR comment per workspace
        --> outputs.changes / to_add / to_change / to_destroy

Merge to main (same matrix)
  --> dflook/terraform-apply  workspace=<name>  label=ecs-<name>
        --> apply only if it matches the reviewed comment for that workspace
```

That is Terraform managing the diff. Git is only the review and merge vehicle.

## 2. Why dflook instead of a shell script

Module 07 runs `terraform plan -out=tfplan` in a working directory. That works.
dflook adds the pieces teams usually forget:

| Concern | Shell workflow | dflook |
| --- | --- | --- |
| Show the plan to reviewers | Upload a log, hope someone opens it | PR comment, updated in place |
| Apply the reviewed plan | Easy to `apply` a *new* plan after merge | Compares logical plan to the comment |
| Plan identity | Filename on a runner that is gone | Comment + label (`ecs-dev`, `ecs-staging`, `ecs-prod`) |
| Drift | Homegrown `plan -detailed-exitcode` | `terraform-check` |
| Terraform version | `setup-terraform` pin | Reads `required_version` |

You still need OIDC, a backend, and branch protection. dflook does not replace
those.

## 3. Workspaces instead of tfvars

One Terraform root. Three environments. **No `dev.tfvars` / `prod.tfvars`.**

```hcl
# workspaces.tf
locals {
  env = {
    dev     = { vpc_cidr_block = "10.90.0.0/16", ecs_desired_count = 0, assign_public_ip = true,  enable_nat_gateway = false }
    staging = { vpc_cidr_block = "10.91.0.0/16", ecs_desired_count = 0, assign_public_ip = true,  enable_nat_gateway = false }
    prod    = { vpc_cidr_block = "10.92.0.0/16", ecs_desired_count = 1, assign_public_ip = false, enable_nat_gateway = true }
  }

  settings = lookup(local.env, terraform.workspace, local.env.dev)
}
```

```bash
terraform workspace select dev      # CIDR 10.90, desired count 0, public tasks
terraform workspace select staging  # CIDR 10.91, desired count 0
terraform workspace select prod     # CIDR 10.92, desired count 1, private + NAT
```

dflook does the select for you:

```yaml
with:
  path: terraform
  workspace: ${{ matrix.workspace }}   # dev | staging | prod
  label: ecs-${{ matrix.workspace }}
```

State: **one** backend key `ecs-dflook/terraform.tfstate`. The S3 backend stores
named workspaces at `env:/<workspace>/ecs-dflook/terraform.tfstate`. Do not put
`/dev` in the key — that would be the old tfvars/directory pattern.

`terraform_data.workspace_guard` fails a plan in the `default` workspace so
nobody applies unnamed state by accident.

Module 07 still prefers **directory-per-environment** when accounts differ.
This lab uses workspaces because the stacks are the same root with different
numbers, and dflook has a first-class `workspace` input.

## 4. Project layout

Treat `project/` as a **repository root** when you copy it out:

```text
project/
  terraform/                 # one root, three workspaces
    workspaces.tf            # env map keyed by terraform.workspace
    versions.tf              # partial backend "s3" {}
    *.tf
    backend.hcl.example      # ONE state key for all workspaces
  .github/workflows/
    lint.yml
    terraform-plan.yml       # matrix: dev, staging, prod
    terraform-apply.yml
    terraform-drift.yml
    terraform-pr-comment.yml
```

ECS objects match Module 13. `dev` and `staging` keep `ecs_desired_count = 0`.
`prod` uses 1 task, private subnets, and NAT (billable). Prefer plan-only in class.

## 5. Workflows

### lint — fmt only

`dflook/terraform-fmt-check@v2` runs `terraform fmt -check`. No AWS credentials.

### terraform-plan — Terraform’s diff per workspace

```yaml
strategy:
  matrix:
    workspace: [dev, staging, prod]

- uses: dflook/terraform-new-workspace@v2
  with:
    path: terraform
    workspace: ${{ matrix.workspace }}

- uses: dflook/terraform-plan@v2
  with:
    path: terraform
    workspace: ${{ matrix.workspace }}
    label: ecs-${{ matrix.workspace }}
    backend_config: |
      bucket=${{ vars.TF_STATE_BUCKET }}
      key=ecs-dflook/terraform.tfstate
      region=us-east-1
      dynamodb_table=${{ vars.TF_LOCK_TABLE }}
      encrypt=true
```

No `var_file`. `label` must match apply for that workspace (`ecs-dev` with
`ecs-dev`, never mix).

Outputs that come from Terraform, not Git:

- `changes` — `true` if the plan would change anything
- `to_add` / `to_change` / `to_destroy`

### terraform-apply — reviewed plan only

On push to `main`, the same matrix applies each workspace’s reviewed comment.

If someone applied from a laptop, or AWS drifted, apply fails with
`plan-changed`. Re-run plan on a new PR.

`auto_approve: true` skips that check. Do not use it for production ECS.

### terraform-drift — scheduled plan

`dflook/terraform-check@v2` with `workspace:` fails when that workspace’s plan
is not empty.

### terraform-pr-comment — on-demand

Comment `terraform plan` to plan every workspace. Comment
`terraform apply staging` (exact workspace name) to apply only that workspace.

## 6. AWS authentication

dflook does not log in to AWS. Set `AWS_*` the usual way. This lab uses OIDC:

```yaml
permissions:
  id-token: write
  contents: read
  pull-requests: write

environment: ${{ matrix.workspace }}  # GitHub Environment named dev|staging|prod

- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: us-east-1
```

Create GitHub Environments `dev`, `staging`, and `prod`. Put `AWS_ROLE_ARN` on
each (prod can require reviewers). Trust
`repo:ORG/REPO:environment:prod` for the prod role. Copy
`TF_STATE_BUCKET` and `TF_LOCK_TABLE` to each environment (same bucket; workspace
isolates the key prefix).

Do not put `AWS_ACCESS_KEY_ID` in GitHub secrets for this lab.

## 7. Local loop

```bash
cd modules/16-aws-ecs-dflook/project/terraform
terraform init -backend=false
terraform workspace new dev        # once
terraform workspace select dev
terraform fmt
terraform validate
# terraform plan   # needs AWS + backend.hcl; guard rejects the default workspace
```

There is no tfvars file. Change CIDR or desired count in `workspaces.tf`, then
select the workspace. `terraform plan` in `default` fails the workspace guard
on purpose.

To run the Actions as written, copy `project/` to its own repository so
`.github/workflows/` and `terraform/` sit at the root.

## 8. Production practices

- Require PR reviews, dismiss stale approvals, require the plan check, require
  branches up to date (dflook apply README).
- One dflook `label` per workspace (`ecs-dev`, `ecs-staging`, `ecs-prod`).
- GitHub Environment name equals the Terraform workspace (`dev` / `staging` /
  `prod`). Bind OIDC to that environment.
- One S3 backend key; named workspaces isolate state under `env:/<workspace>/`.
  Do not encode `/dev` in the key.
- Never apply the `default` workspace.
- Pin dflook to a release SHA in real repos (`@v2` is for teaching).
- Drift job on a schedule, per workspace; treat failures as incidents, not noise.
- Keep image rollouts out of this state file if a deployer owns task revisions
  (same lesson as Module 13 `desired_count`).

## 9. Common mistakes

1. Using `paths:` + `git diff` to skip `terraform plan` “because no `.tf`
   files changed.”
2. `auto_approve: true` on production apply.
3. Different `label` on plan vs apply, or mixing `ecs-dev` with `ecs-prod`.
4. Static AWS keys in GitHub.
5. Applying from a laptop after the PR plan, then wondering why merge apply
   reports `plan-changed`.
6. Path filters copied from the Module 14 app CI onto this Terraform root.
7. Leaving an applied ALB running after class.
8. Applying the `default` workspace (the guard exists because this is easy).
9. Putting `/dev` or `/prod` in the backend `key` and then also using workspaces
   — you get two isolation mechanisms stacked, and state paths that nobody
   expects.
10. Reintroducing `dev.tfvars` / `prod.tfvars` instead of editing `workspaces.tf`.

## 10. Interview Q&A

**Why isn’t git diff enough for Terraform CI?**
Git sees files. Terraform sees desired config versus state versus the live API.
Drift, data sources, and provider upgrades do not show up as a useful git diff.

**What does dflook apply actually compare?**
A new plan from current config/state against the plan that was commented on the
PR. If they differ, it refuses to apply.

**When are path filters acceptable?**
To avoid running *unrelated* pipelines (a Go test job). Not as the definition
of an infrastructure change. If you filter Terraform jobs, you still need a
scheduled `terraform-check`.

**Why workspaces instead of tfvars here?**
The root is the same stack with different numbers (CIDR, desired count, NAT).
`terraform.workspace` is the switch. dflook has a first-class `workspace:`
input, so CI does not need `var_file: env/dev.tfvars`.

**Why one backend key for three environments?**
The S3 backend already namespaces named workspaces
(`env:/dev/ecs-dflook/terraform.tfstate`). A second `/dev` in the key is the
old directory/tfvars pattern and makes workspace state hard to find.

**How is this different from Module 07?**
Module 07 prefers directory-per-environment when AWS accounts differ. This lab
uses workspaces because it is one root, one account, and dflook can select the
workspace. Module 07 also taught shell plan/apply; this module stores the plan
on the PR and makes apply prove it is still the same plan.

**What happens if you plan in the `default` workspace?**
`terraform_data.workspace_guard` fails. Named workspaces only.

## Mini project

Complete the exercises. Then add a fourth workspace `qa` in `workspaces.tf`
(new CIDR block, desired count 0, public IP) and add `qa` to the workflow
matrix plus a GitHub Environment of the same name. Do not add `qa.tfvars` or a
second backend key. Do not introduce `git diff` to split the environments.

## Further reading

- dflook actions: https://github.com/dflook/terraform-github-actions
- terraform-plan: https://github.com/dflook/terraform-github-actions/tree/main/terraform-plan
- terraform-apply: https://github.com/dflook/terraform-github-actions/tree/main/terraform-apply
- terraform-check: https://github.com/dflook/terraform-github-actions/tree/main/terraform-check
- Module 13 ECS: [../13-aws-ecs/](../13-aws-ecs/)
- Module 07 production CI: [../07-production/](../07-production/)
