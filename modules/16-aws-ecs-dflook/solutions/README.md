# Module 16 Solutions — ECS + dflook

These answers correspond to `../exercises/README.md`.

## Exercise 1: Git diff vs Terraform plan

1. **Git yes, Terraform no:** a README or workflow-comment change. Config and
   state still match. Plan: `No changes.`
2. **Git no, Terraform yes:** someone changed the ALB security group in the
   console; or a data source (AMI, latest image digest) moved; or another
   process updated desired count. `git diff` is empty. Plan is not.

Skipping plan because Git omitted `.tf` files hides (2).

## Exercise 2: Trace the workflows

| File | Trigger | Action | OIDC | git `paths:` |
| --- | --- | --- | --- | --- |
| `lint.yml` | PR / push main | `terraform-fmt-check` | no | no |
| `terraform-plan.yml` | `pull_request` | `terraform-plan` | yes | no |
| `terraform-apply.yml` | push `main` | `terraform-apply` | yes | no |
| `terraform-drift.yml` | cron / dispatch | `terraform-check` | yes | no |
| `terraform-pr-comment.yml` | issue_comment | plan or apply | yes | no |

## Exercise 3: Plan identity

1. Apply cannot find the matching PR comment. The plan and apply labels must be
   identical (`ecs-dev`).
2. Current config/state/AWS would not apply the same actions as the reviewed
   comment. Someone applied elsewhere, AWS drifted, or new commits landed.
   Do not force-apply; plan again.
3. `auto_approve` generates and applies a *new* plan, skipping the reviewed
   comment. That throws away the whole point of this module.

## Exercise 4: Contrast Module 14

1. Flask tests and Docker builds are expensive. Path filters keep a docs PR
   from rebuilding Go images. That is CI time, not an AWS truth.
2. ECS/ALB/IAM truth is in Terraform state. A path filter would skip the only
   tool that can see drift. This lab always plans.
3. `dflook/terraform-check` on a schedule (`terraform-drift.yml`).

## Exercise 5

Git: README only. Terraform comment: usually **No changes** (or only tag
noise if you tagged resources from a different var). The useful part is that
the plan still ran.

## Interview drill

1. Terraform (`terraform plan` via dflook), compared to remote state and AWS
   APIs. Git is the review channel.
2. So a workflow that is not using Environment `dev` cannot assume the dev
   role. Stolen YAML without `environment: dev` does not get the role.
3. Module 07 apply runs `terraform apply` on whatever plan the runner just
   created. dflook apply requires that plan to match the PR comment, or it
   fails with `plan-changed`.
