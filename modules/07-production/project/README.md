# Enterprise Terraform Repository Skeleton

This project is a safe, educational production-style Terraform repository for
AWS. It uses placeholders for backend buckets, account IDs, and role names.
Replace them with values from your own sandbox before running Terraform.

## Layout

```text
.
|-- live/
|   |-- dev/
|   |-- staging/
|   `-- prod/
|-- modules/
|   |-- networking/
|   `-- app/
`-- .github/workflows/terraform.yml
```

## Environments

Each `live/<env>` directory owns its own backend, provider config, and module
calls. This keeps state boundaries explicit and lets CI run plans based on path
filters.

| Environment | Intended AWS account | Notes |
| --- | --- | --- |
| dev | workload-dev | Small CIDR and low capacity |
| staging | workload-staging | Production-like validation |
| prod | workload-prod | Stronger deletion protection and approvals |

## Before use

1. Create a remote state S3 bucket and DynamoDB lock table per environment.
2. Replace placeholder account IDs and role ARNs in `providers.tf`.
3. Review CIDR ranges and names.
4. Configure GitHub Actions OIDC trust in AWS.
5. Commit changes through pull requests and review the plan output.

## Commands

```bash
cd live/dev
terraform init
terraform fmt -recursive ../..
terraform validate
terraform plan
```

The workflow demonstrates plan-on-PR and apply-on-main behavior. Production
apply should be protected by GitHub environment approvals.

