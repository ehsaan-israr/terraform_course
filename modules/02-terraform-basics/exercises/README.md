# Module 2 Exercises - Solution Hints

These exercises focus on core Terraform syntax and workflow. Use the Module 2 project as your starting point.

## Exercise 1: Add variable validation

Add a variable named `allowed_http_cidr` and use it in the HTTP ingress rule instead of hard-coding `0.0.0.0/0`.

Tasks:

1. Add the variable with type `string`.
2. Add validation using `can(cidrhost(...))`.
3. Test with a valid CIDR and an invalid string.

Solution hints:

- The validation condition should return true or false.
- `cidrhost(var.allowed_http_cidr, 0)` fails if the value is not a CIDR.
- Wrap the function in `can(...)` to turn failure into false.

## Exercise 2: Turn outputs into a small API

Add outputs for:

- Security group ID.
- AMI ID selected by the data source.
- Availability zone selected by the subnet.

Tasks:

1. Add the outputs.
2. Run `terraform plan`.
3. Identify which outputs are known before apply.

Solution hints:

- Data source values are usually known during plan.
- Instance values such as `id` are known only after apply.
- Good outputs are stable and useful to humans or downstream automation.

## Exercise 3: Refactor repeated tags with locals

Add an `Owner` tag to every resource without copy-pasting it into every resource block.

Tasks:

1. Add a variable named `owner`.
2. Add `Owner = var.owner` to `local.common_tags`.
3. Run `terraform plan` and inspect tag changes.

Solution hints:

- Provider `default_tags` applies tags to supported AWS resources.
- Resource-specific `tags` should usually contain `Name` and any exceptions.
- Centralizing tags reduces drift across resources.
