# Exercises: Module 11 Terraform Ecosystem

## Exercise 1: Choose the workflow

For each scenario, choose Terragrunt, Atlantis, Terraform Cloud, Spacelift, OpenTofu, Infracost, or a combination:

1. A small team has three Terraform roots and wants free GitHub Actions plans.
2. A regulated enterprise needs self-hosted runners in a private network.
3. A platform team manages 200 stacks across 30 accounts.
4. A finance team wants cost deltas on every pull request.
5. A company requires an open-source Terraform-compatible engine.

Deliverable: one-page decision memo with tradeoffs.

## Exercise 2: Extend the Terragrunt live layout

Add a `staging` environment next to `env/dev` in `modules/11-ecosystem/project/terragrunt`.

Deliverables:

- `env/staging/terragrunt.hcl`.
- Different CIDR block and tags.
- Explanation of which values are inherited from `root.hcl`.

## Exercise 3: Design a GitOps approval flow

Draw or write a workflow that includes:

- Pull request opened.
- fmt and validate.
- security scan.
- plan comment.
- cost estimate.
- approval.
- apply with lock.
- drift detection.

Deliverable: ASCII diagram plus a paragraph describing production safeguards.
