# Module 16 - AWS ECS with dflook Terraform GitHub Actions

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
Pull request
  --> dflook/terraform-plan
        --> terraform init + plan against S3 state
        --> PR comment with the human-readable plan
        --> outputs.changes / to_add / to_change / to_destroy

Merge to main
  --> dflook/terraform-apply
        --> generate a fresh plan
        --> apply only if it matches the reviewed PR comment
        --> fail with plan-changed if AWS or config moved
```

That is Terraform managing the diff. Git is only the review and merge vehicle.

## 2. Why dflook instead of a shell script

Module 07 runs `terraform plan -out=tfplan` in a working directory. That works.
dflook adds the pieces teams usually forget:

| Concern | Shell workflow | dflook |
| --- | --- | --- |
| Show the plan to reviewers | Upload a log, hope someone opens it | PR comment, updated in place |
| Apply the reviewed plan | Easy to `apply` a *new* plan after merge | Compares logical plan to the comment |
| Plan identity | Filename on a runner that is gone | Comment + label (`ecs-dev`) |
| Drift | Homegrown `plan -detailed-exitcode` | `terraform-check` |
| Terraform version | `setup-terraform` pin | Reads `required_version` |

You still need OIDC, a backend, and branch protection. dflook does not replace
those.

## 3. Project layout

Treat `project/` as a **repository root** when you copy it out:

```text
project/
  terraform/                 # ECS Fargate root (same pattern as Module 13)
    versions.tf              # partial backend "s3" {}
    *.tf
    terraform.tfvars.example
    backend.hcl.example
  .github/workflows/
    lint.yml                 # dflook/terraform-fmt-check
    terraform-plan.yml       # PR: plan + comment
    terraform-apply.yml      # main: apply reviewed plan
    terraform-drift.yml      # schedule: terraform-check
    terraform-pr-comment.yml # optional: comment `terraform plan` / `terraform apply`
```

The ECS objects are the same as Module 13 (cluster, task definition, service,
ALB, two IAM roles). Defaults keep `ecs_desired_count = 0` so a mistaken apply
does not start Fargate tasks. The ALB is still billable if you apply.

## 4. Workflows

### lint — fmt only

`dflook/terraform-fmt-check@v2` runs `terraform fmt -check`. No AWS credentials.
This is not an infrastructure diff; it is a style gate.

### terraform-plan — Terraform’s diff

```yaml
- uses: dflook/terraform-plan@v2
  with:
    path: terraform
    label: ecs-dev
    var_file: terraform/terraform.tfvars.example
    backend_config: |
      bucket=${{ vars.TF_STATE_BUCKET }}
      key=ecs-dflook/dev/terraform.tfstate
      region=us-east-1
      dynamodb_table=${{ vars.TF_LOCK_TABLE }}
      encrypt=true
```

`label` must match apply. Multiple roots (dev vs prod) use different labels so
comments do not collide.

Outputs that come from Terraform, not Git:

- `changes` — `true` if the plan would change anything
- `to_add` / `to_change` / `to_destroy`

### terraform-apply — reviewed plan only

On push to `main`, dflook finds the merged PR, reads the `ecs-dev` plan comment,
plans again, and applies if the plans are logically the same.

If someone applied from a laptop, or AWS drifted, apply fails with
`plan-changed`. That is success of the control, not a mystery CI bug. Re-run
plan on a new PR.

`auto_approve: true` skips that check. Do not use it for production ECS.

### terraform-drift — scheduled plan

`dflook/terraform-check@v2` fails the job when the plan is not empty. Console
edits to the ECS service or security group show up here even when Git is clean.

### terraform-pr-comment — on-demand

Comment `terraform plan` or `terraform apply` on the PR. The workflow checks
out `refs/pull/<n>/merge` and runs Terraform. Still not `git diff`.

## 5. AWS authentication

dflook does not log in to AWS. Set `AWS_*` the usual way. This lab uses OIDC:

```yaml
permissions:
  id-token: write
  contents: read
  pull-requests: write

- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: us-east-1
```

Store `AWS_ROLE_ARN` on GitHub Environment `dev`. Trust
`repo:ORG/REPO:environment:dev`. Plan roles need read + state lock; apply roles
need write to ECS, VPC, IAM, ELB, logs, and the state bucket.

Do not put `AWS_ACCESS_KEY_ID` in GitHub secrets for this lab.

## 6. Local loop

```bash
cd modules/16-aws-ecs-dflook/project/terraform
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
terraform fmt
terraform validate
# terraform plan   # needs AWS + a real backend for the CI-shaped flow
```

CI needs a committed `terraform.tfvars.example` (defaults, no account IDs).
Never commit `terraform.tfvars`.

To run the Actions as written, copy `project/` to its own repository so
`.github/workflows/` and `terraform/` sit at the root.

## 7. Production practices

- Require PR reviews, dismiss stale approvals, require the plan check, require
  branches up to date (dflook apply README).
- One label per Terraform root / environment.
- OIDC bound to the GitHub Environment name.
- Remote state + lock table per environment.
- Pin dflook to a release SHA in real repos (`@v2` is for teaching).
- Drift job on a schedule; treat failures as incidents, not noise.
- Keep image rollouts out of this state file if a deployer owns task revisions
  (same lesson as Module 13 `desired_count`).

## 8. Common mistakes

1. Using `paths:` + `git diff` to skip `terraform plan` “because no `.tf`
   files changed.”
2. `auto_approve: true` on production apply.
3. Different `label` on plan vs apply.
4. Static AWS keys in GitHub.
5. Applying from a laptop after the PR plan, then wondering why merge apply
   reports `plan-changed`.
6. Path filters copied from the Module 14 app CI onto this Terraform root.
7. Leaving an applied ALB running after class.

## 9. Interview Q&A

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

**How is this different from Module 07?**
Module 07 teaches the plan/apply loop in CI. This module stores the plan on the
PR and makes apply prove it is still the same plan.

## Mini project

Complete the exercises. Then add a second label `ecs-prod` with its own
backend key and GitHub Environment, reusing the same workflow shape (matrix or
copied jobs). Do not introduce `git diff` to split the environments.

## Further reading

- dflook actions: https://github.com/dflook/terraform-github-actions
- terraform-plan: https://github.com/dflook/terraform-github-actions/tree/main/terraform-plan
- terraform-apply: https://github.com/dflook/terraform-github-actions/tree/main/terraform-apply
- terraform-check: https://github.com/dflook/terraform-github-actions/tree/main/terraform-check
- Module 13 ECS: [../13-aws-ecs/](../13-aws-ecs/)
- Module 07 production CI: [../07-production/](../07-production/)
