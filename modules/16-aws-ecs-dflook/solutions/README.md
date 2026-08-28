# Module 16 Solutions — ECS + dflook + workspaces

These answers correspond to `../exercises/README.md`.

## Exercise 1: Git diff vs Terraform plan

1. **Git yes, Terraform no:** a README or workflow-comment change. Config and
   state still match. Plan: `No changes.`
2. **Git no, Terraform yes:** someone changed the ALB security group in the
   console; or a data source (AMI, latest image digest) moved; or another
   process updated desired count. `git diff` is empty. Plan is not.

Skipping plan because Git omitted `.tf` files hides (2).

## Exercise 2: Trace the workflows

| File | Trigger | Action | OIDC | git `paths:` | Workspaces |
| --- | --- | --- | --- | --- | --- |
| `lint.yml` | PR / push main | `terraform-fmt-check` | no | no | none (fmt all HCL) |
| `terraform-plan.yml` | `pull_request` | `new-workspace` + `terraform-plan` | yes | no | matrix `dev/staging/prod`, `label: ecs-<ws>` |
| `terraform-apply.yml` | push `main` | `new-workspace` + `terraform-apply` | yes | no | same matrix and labels |
| `terraform-drift.yml` | cron / dispatch | `terraform-check` | yes | no | same matrix |
| `terraform-pr-comment.yml` | issue_comment | plan all, or apply one | yes | no | plan: all three; apply: comment must contain `terraform apply dev` (etc.) |

## Exercise 3: Plan identity per workspace

1. Apply cannot find the matching PR comment. The plan and apply labels must be
   identical (`ecs-dev` with `ecs-dev`).
2. Prod would try to apply the *dev* reviewed plan. Labels must not cross
   workspaces.
3. Current config/state/AWS would not apply the same actions as the reviewed
   comment. Someone applied elsewhere, AWS drifted, or new commits landed.
   Do not force-apply; plan again.
4. `auto_approve` generates and applies a *new* plan, skipping the reviewed
   comment. That throws away the whole point of this module.

## Exercise 4: Contrast Module 14

1. Flask tests and Docker builds are expensive. Path filters keep a docs PR
   from rebuilding Go images. That is CI time, not an AWS truth.
2. ECS/ALB/IAM truth is in Terraform state. A path filter would skip the only
   tool that can see drift. This lab always plans.
3. `dflook/terraform-check` on a schedule (`terraform-drift.yml`), once per
   workspace.

## Exercise 5

Git: README only. Terraform comments: usually **No changes** in each workspace
(or only tag noise). The useful part is that three plans still ran, with three
labels.

## Exercise 6: Workspaces instead of tfvars

1. `local.env` in `workspaces.tf`, selected with `lookup(..., terraform.workspace, ...)`.
   Shared inputs (`aws_region`, image, AZs) stay in `variables.tf` with defaults.
   Env-wise numbers are not tfvars because the switch is the workspace name.
2. The S3 backend already stores named workspaces at
   `env:/<workspace>/ecs-dflook/terraform.tfstate`. Putting `/dev` in the key
   is the old per-env-directory pattern and double-namespaces state.
3. `terraform_data.workspace_guard` fails the precondition. Validate still
   works because of the lookup fallback.
4. This lab is one root, one account, stacks that differ only in numbers, and
   dflook has `workspace:`. Module 07 still wants directories when accounts
   and approval boundaries differ.

## Interview drill

1. Terraform (`terraform plan` via dflook), compared to remote state and AWS
   APIs. Git is the review channel.
2. So a workflow that is not using Environment `prod` cannot assume the prod
   role. Stolen YAML without `environment: prod` does not get the prod role.
   The GitHub Environment name matches the Terraform workspace.
3. Module 07 apply runs `terraform apply` on whatever plan the runner just
   created. dflook apply requires that plan to match the PR comment, or it
   fails with `plan-changed`.
4. That would reintroduce tfvars as the env switch. This lab keys env
   settings off `terraform.workspace` in HCL so there is one root, no
   `var_file`, and CI only passes `workspace:`.
