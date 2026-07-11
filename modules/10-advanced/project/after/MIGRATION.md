# Migration Guide: Monolith to Modules

This migration keeps the same AWS resources and changes only Terraform addresses.

## Pre-check

Run the old root module first and verify the plan is clean:

```bash
terraform init
terraform plan
```

If the plan shows unrelated drift, resolve it before refactoring.

## Address map

| Old address | New address |
| --- | --- |
| `aws_vpc.main` | `module.networking.aws_vpc.this` |
| `aws_internet_gateway.main` | `module.networking.aws_internet_gateway.this` |
| `aws_subnet.public` | `module.networking.aws_subnet.public` |
| `aws_route_table.public` | `module.networking.aws_route_table.public` |
| `aws_route_table_association.public` | `module.networking.aws_route_table_association.public` |
| `aws_security_group.web` | `module.web_security_group.aws_security_group.this` |
| `aws_instance.web` | `module.web.aws_instance.this` |

## Moved block pattern

Before the refactor, state contains:

```hcl
aws_instance.web
```

After the refactor, configuration contains:

```hcl
module "web" {
  source = "./modules/compute"
}
```

The move declaration connects the two addresses:

```hcl
moved {
  from = aws_instance.web
  to   = module.web.aws_instance.this
}
```

## Apply sequence

1. Commit the monolithic code with a clean plan.
2. Add the modules, root module calls, and `moved.tf` in one migration commit.
3. Run `terraform init` so local modules are discovered.
4. Run `terraform plan` and confirm the output says resources moved instead of destroyed.
5. Apply in a lower environment first.
6. Promote the exact same change to staging and production.

## What not to do

- Do not rename resources and change arguments in the same pull request.
- Do not remove moved blocks before all long-lived workspaces have applied the migration.
- Do not use `terraform state mv` manually unless you have a documented reason and peer review.
