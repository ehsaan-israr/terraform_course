# Advanced Terraform Project: Monolith to Modules

This project demonstrates a common production refactor: a single root module with networking, security, and compute resources is split into reusable modules.

## Structure

```text
before/
  monolith.tf              # Everything mixed in one root module
after/
  versions.tf
  variables.tf
  main.tf                  # Clean root module composition
  moved.tf                 # State address migration declarations
  outputs.tf
  MIGRATION.md
  modules/
    networking/
    security-group/
    compute/
```

## How to study this project

1. Start with `before/monolith.tf`.
2. Identify the VPC, subnet, routing, security group, and EC2 resources.
3. Open `after/main.tf` and see how the root module now composes smaller modules.
4. Open `after/moved.tf` and match every old address to a new address.
5. Read `after/MIGRATION.md` for the staged workflow.

## Important lesson

The refactor does not require destroying resources. The `moved` blocks preserve Terraform state lineage when resource addresses change.
