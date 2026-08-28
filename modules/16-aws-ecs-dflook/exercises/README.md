# Module 16 Exercises — ECS + dflook

Use `../project`. Exercises 1–4 need no AWS.

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

## Exercise 3: Plan identity

`terraform-plan.yml` and `terraform-apply.yml` share `label: ecs-dev`.

1. What breaks if apply uses `label: ecs` instead?
2. What does `failure_reason=plan-changed` mean after merge?
3. Why is `auto_approve: true` the wrong default for this ECS root?

## Exercise 4: Contrast Module 14

Module 14 `project-cicd` uses path filters so a Flask change does not plan
every Terraform root.

1. Why is that reasonable for *application* CI?
2. Why does this module refuse path filters on plan/apply?
3. Which dflook action still catches ECS drift if nobody opens a Terraform PR?

## Exercise 5 (optional, sandbox)

Copy `project/` to a throwaway repo, configure Environment `dev`, and open a PR
that only changes `project/README.md` (or the copied root README).

Deliverable: the plan comment. Did Terraform report changes? What did Git show?

## Interview drill

1. Who computes the infrastructure diff in this lab?
2. Why bind OIDC to `environment:dev`?
3. How is dflook apply stricter than `terraform apply -auto-approve` in Module 07?
