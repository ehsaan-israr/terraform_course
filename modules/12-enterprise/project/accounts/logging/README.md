# Logging Account

Central log archive: CloudTrail, VPC Flow Logs, ALB/WAF logs, S3 access logs, retention controls, and immutable storage.

## What lives here

- Account-scoped root module composition.
- Provider configuration that assumes a deployment role into this account.
- Account-specific resources and calls to shared modules.
- Outputs consumed by neighboring accounts only through explicit remote state or published parameters.

## Operating guidance

- Keep this root small and readable.
- Do not place unrelated account resources here.
- Require pull request review for all changes.
- Run plans with credentials scoped to this account.
