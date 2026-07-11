# Enterprise Multi-Account Skeleton

This project is a teaching scaffold for account-aligned Terraform. Each folder under `accounts/` represents a root module that assumes a role into one AWS account.

## Account layout

```text
accounts/
  networking/        # Transit, shared VPC, DNS resolver, central egress
  shared-services/   # ECR, CI runners, internal tooling
  security/          # GuardDuty, Security Hub, security automation
  logging/           # Centralized immutable log storage
  staging/           # Production-like pre-release workloads
  production/        # Customer-facing workloads
```

## Provider model

Each root module includes this pattern:

```hcl
provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/${var.role_name}"
  }
}
```

CI should authenticate to a central deployment role, then assume the environment-specific role. This keeps production credentials out of developer laptops and gives CloudTrail a clear audit path.

## Remote state recommendation

Use one state file per account root. A common key pattern is:

```text
enterprise/accounts/<account-name>/terraform.tfstate
```

Keep state buckets encrypted, versioned, access logged, and restricted to CI roles plus break-glass administrators.
