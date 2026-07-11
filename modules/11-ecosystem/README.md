# Module 11: Terraform Ecosystem

Terraform is one tool in a larger delivery system. Mature teams need wrappers, policy checks, pull request automation, cost review, remote execution, secrets handling, and drift visibility. This module explains the surrounding ecosystem and how to choose the right tool for a team.

## Learning objectives

By the end of this module you should be able to:

- Explain what Terragrunt, Atlantis, Terraform Cloud, Spacelift, OpenTofu, and Infracost solve.
- Design a pull-request-based GitOps workflow for infrastructure changes.
- Compare managed runners with self-hosted workflows.
- Decide when a wrapper adds useful structure and when it adds unnecessary complexity.
- Describe how cost estimation and policy checks fit into CI/CD.

## Terragrunt

Terragrunt is a thin wrapper around Terraform/OpenTofu. It helps with DRY remote state configuration, hierarchical live configuration, dependency outputs between stacks, and running plans across many stacks.

Use Terragrunt when you manage many similar root modules and need consistent state, providers, and environment layout. Avoid it for tiny repositories where plain Terraform roots are easy to understand.

## Atlantis

Atlantis is a self-hosted pull request automation service for Terraform. It listens to VCS webhooks, runs `plan` on pull requests, comments the output, locks projects, and applies after approval.

Use Atlantis when you want GitHub/GitLab/Bitbucket PR automation but need to own the runner and network path.

## Terraform Cloud

Terraform Cloud provides remote state, private module registry, policy as code, remote execution, run tasks, drift detection, variable sets, and team access controls.

Use Terraform Cloud when you want a managed Terraform workflow with strong integration into the HashiCorp ecosystem and do not want to build your own runner platform.

## Spacelift

Spacelift is a managed infrastructure orchestration platform that supports Terraform, OpenTofu, Terragrunt, Pulumi, CloudFormation, and Kubernetes workflows. It emphasizes stacks, dependencies, policies, drift detection, worker pools, and multi-tool orchestration.

Use Spacelift when your organization needs a broader IaC control plane, policy workflows, and flexible self-hosted workers.

## OpenTofu

OpenTofu is an open-source fork of Terraform created after Terraform's license change. Use it when your organization requires an open-source license posture or wants to standardize on the community fork. Validate provider and module compatibility before migration.

## Infracost

Infracost estimates cloud cost changes from Terraform plans and comments on pull requests. It helps engineers see monthly cost impact before apply.

## Comparison table

| Tool | Primary purpose | Best fit | Tradeoffs |
| --- | --- | --- | --- |
| Terragrunt | DRY live configuration wrapper | Many accounts/environments/stacks | Adds another language and workflow layer |
| Atlantis | Self-hosted PR automation | Teams needing VCS-driven plans in private networks | You operate the service |
| Terraform Cloud | Managed Terraform platform | Teams wanting remote execution, state, policy, registry | SaaS dependency and pricing model |
| Spacelift | IaC orchestration platform | Multi-tool, multi-cloud platform teams | Platform adoption and stack design required |
| OpenTofu | Open-source Terraform-compatible engine | License-sensitive organizations | Ecosystem compatibility must be verified |
| Infracost | Cost estimation | PR cost visibility and FinOps review | Estimates depend on supported resources and pricing assumptions |

## GitOps workflow

```text
Developer
   |
   | 1. branch + edit Terraform
   v
Pull Request
   |
   | 2. fmt, validate, security scan
   v
Plan Runner --------------------+
   |                            |
   | 3. terraform plan          | 4. infracost estimate
   v                            v
PR Comments: Plan + Cost + Policy Results
   |
   | 5. review + approval
   v
Apply Runner with Lock
   |
   | 6. terraform apply
   v
Remote State + Cloud Resources
   |
   | 7. drift checks and monitoring
   v
Operations Feedback
```

## Choosing a workflow

Start with the simplest workflow that enforces remote state and locking, reviewed plans, separate credentials per environment, security scanning, cost visibility, and an audit trail. Then add tools only when they solve an observed problem.

## Interview questions

1. What problem does Terragrunt solve that Terraform modules alone do not?
2. How does Atlantis prevent two applies from racing against each other?
3. What is the difference between remote state and remote execution?
4. Why might an enterprise choose Spacelift over a simple GitHub Actions workflow?
5. What are the migration considerations for OpenTofu?
6. Where should cost estimation happen in a GitOps workflow?
7. How would you design credentials for dev, staging, and prod CI runners?
8. What policy checks would you require before applying production Terraform?

## Case study

A company has 80 Terraform roots across 12 AWS accounts. Engineers run plans locally, state backends are inconsistent, and production applies happen from laptops. The platform team wants pull request review, consistent state naming, and cost estimates.

A pragmatic path:

1. Standardize repository layout by account and environment.
2. Adopt Terragrunt for repeated backend and provider configuration.
3. Add Atlantis or a managed runner for pull request plans.
4. Require approvals before production apply.
5. Add Infracost comments for cost deltas.
6. Add security scans and policy checks after the plan stage is stable.
7. Track drift and feed recurring issues into module improvements.
