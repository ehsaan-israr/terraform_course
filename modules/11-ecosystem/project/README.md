# Ecosystem Project: Terragrunt GitOps Layout

This project shows a minimal Terragrunt live layout with a reusable VPC module. It also includes lightweight Atlantis and Infracost examples so you can compare workflow options.

## Structure

```text
terragrunt/
  root.hcl
  modules/vpc/
  env/dev/terragrunt.hcl
atlantis.yaml
.github/workflows/infracost-comment.yml
```

## Implementation steps

1. Store Terraform state in a dedicated S3 bucket with DynamoDB locking or native S3 locking where appropriate.
2. Put common backend/provider generation in `terragrunt/root.hcl`.
3. Keep reusable Terraform code under `terragrunt/modules` or a separate module repository.
4. Create live environment folders such as `env/dev`, `env/staging`, and `env/prod`.
5. Run `terragrunt plan` from the live folder.
6. In CI, run formatting, validation, plan, security scan, and cost estimate.
7. Require peer approval before apply.

## Terragrunt vs Atlantis vs Terraform Cloud

- **Terragrunt** organizes and invokes Terraform/OpenTofu. It is not a hosted approval system.
- **Atlantis** runs Terraform from pull request comments and posts plan output. It can call Terragrunt too.
- **Terraform Cloud** provides remote execution, policy, state, and registry features as a managed service.

Many teams combine Terragrunt with Atlantis or a managed runner.
