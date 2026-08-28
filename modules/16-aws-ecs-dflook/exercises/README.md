# Module 16 Exercises — ECS + dflook + workspaces

Use `../project`. Exercises 1–4 and 6 need no AWS.

## Exercise 1: Git diff vs Terraform plan

Write two situations:

1. Git shows a diff, Terraform plan is empty.
2. Git shows no `.tf` diff, Terraform plan is not empty.

Success criteria: you would not skip `terraform-plan.yml` because
`git diff --name-only` omitted `terraform/`.

## Exercise 2: Trace the workflows

Open `.github/workflows/`. For each file, write:

- Trigger
- dflook action
- Whether it uses OIDC
- Whether it uses `paths:` / git diff
- How workspaces are selected (`matrix.workspace`, `workspace:`, `label:`)

## Exercise 3: Plan identity per workspace

`terraform-plan.yml` and `terraform-apply.yml` share
`label: ecs-${{ matrix.workspace }}` (`ecs-dev`, `ecs-staging`, `ecs-prod`).

1. What breaks if apply uses `label: ecs` instead of `ecs-dev`?
2. What happens if the prod apply job uses `label: ecs-dev`?
3. What does `failure_reason=plan-changed` mean after merge?
4. Why is `auto_approve: true` the wrong default for this ECS root?

## Exercise 4: Contrast Module 14

Module 14 `project-cicd` uses path filters so a Flask change does not plan
every Terraform root.

1. Why is that reasonable for *application* CI?
2. Why does this module refuse path filters on plan/apply?
3. Which dflook action still catches ECS drift if nobody opens a Terraform PR?

## Exercise 5 (optional, sandbox)

Copy `project/` to a throwaway repo, configure GitHub Environments
`dev` / `staging` / `prod`, and open a PR that only changes a README.

Deliverable: the three plan comments. Did Terraform report changes? What did
Git show? Are the labels `ecs-dev`, `ecs-staging`, and `ecs-prod`?

## Exercise 6: Workspaces instead of tfvars

Open `terraform/workspaces.tf` and `terraform/variables.tf`.

1. Where do CIDR, desired count, NAT, and public IP come from? Why is there no
   `dev.tfvars`?
2. Why is the backend key `ecs-dflook/terraform.tfstate` with **no** `/dev`?
3. What happens if you `terraform plan` in the `default` workspace?
4. Module 07 prefers directory-per-environment for separate AWS accounts. Why
   are workspaces the right tool *in this lab*?

## Interview drill

1. Who computes the infrastructure diff in this lab?
2. Why bind OIDC to `environment: ${{ matrix.workspace }}`?
3. How is dflook apply stricter than `terraform apply -auto-approve` in Module 07?
4. Why not pass `var_file: env/${{ matrix.workspace }}.tfvars`?
