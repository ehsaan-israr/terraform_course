# Staging Account

Production-like workload account for release validation, integration tests, and safe operational rehearsals.

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
