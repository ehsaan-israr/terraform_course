# Module 14 Exercises — EKS CI/CD

Use the project in `../project`. Exercises 1–4 do not need AWS.

## Exercise 1: Trace a Flask change

A pull request only changes `services/flask-api/app.py`.

Deliverable:

- Which `ci.yml` jobs run?
- Which jobs are skipped?
- Which deploy workflow would run if the same change landed on `develop`?

## Exercise 2: Map Git refs to environments

Fill in the table from the project README and workflow `on:` blocks:

| Git ref | GitHub Environment | Typical action |
| --- | --- | --- |
| PR into `main` | | |
| Push to `develop` | | |
| Push to `release/1.4` | | |
| Tag `v1.2.3` | | |
| Push to `main` changing `infra/terraform/environments/iaas/**` | | |

## Exercise 3: Terraform state boundaries

Compare `environments/dev` and `environments/prod`.

Deliverable:

- Backend key for each.
- CIDR for each.
- Why these must not share one state file.
- What `REPLACE_ME-tfstate` is telling you.

## Exercise 4: EKS skeleton gap analysis

Read `infra/terraform/modules/vpc/main.tf` and `modules/eks/main.tf`.

List four resources you would add before this cluster could run pods. For each,
say whether Terraform or the deploy workflow should own it.

## Exercise 5 (optional, sandbox): Plan only

In a sandbox account, copy `backend.tf` placeholders, `terraform init`, and
`terraform plan` for `environments/dev`. Do **not** apply unless you accept
EKS control-plane cost and will destroy the same day.

## Interview drill

1. Why OIDC instead of long-lived AWS keys in GitHub?
2. What is the blast radius of applying `environments/prod` vs `environments/iaas`?
3. Why path filters matter in a monorepo?
