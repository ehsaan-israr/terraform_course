# Module 07 Exercises: Production Terraform Engineering

## Exercise 1: Choose an environment layout

Given a team with Dev, UAT, Prod, and preview environments, decide which should
use directory-per-environment and which could use workspaces.

Deliverable:

- A short design note explaining the layout.
- One risk of the chosen approach.
- One CI/CD control that reduces the risk.

## Exercise 2: Design an AWS account topology

Create an ASCII diagram for:

- Dev workload account.
- UAT workload account.
- Prod workload account.
- Shared services account.
- Security/log archive account.

Deliverable:

- Diagram.
- The IAM role path GitHub Actions uses to reach each workload account.
- A sentence describing the blast-radius benefit.

## Exercise 3: Extend the project skeleton

In `../project`:

1. Add a `live/uat` directory based on staging.
2. Give it a unique backend key, account placeholder, CIDR, and tags.
3. Add `uat` to the GitHub Actions matrix.

Deliverable:

- Pull request summary.
- `terraform fmt -check -recursive` output.

## Exercise 4: Blue/green design review

Write a blue/green rollout checklist for the app module.

Include:

- Health check requirement.
- Rollback command or commit strategy.
- Database migration safety requirement.
- Metrics to watch during traffic shift.

## Interview drill

Answer in 2 minutes:

1. Why is directory-per-environment usually safer than workspaces for Prod?
2. How does multi-account AWS reduce blast radius?
3. What should reviewers inspect in a Terraform plan?

