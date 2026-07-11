# Module 3 Exercises - Solution Hints

These exercises practice identity, repetition, dynamic blocks, lifecycle safety, and sensitive values.

## Exercise 1: Convert from count to for_each

Create a temporary resource using `count = 2`, then refactor it to use a map with keys `web-a` and `web-b`.

Tasks:

1. Write down the original addresses, such as `aws_instance.web[0]`.
2. Write down the new addresses, such as `aws_instance.web["web-a"]`.
3. Explain why Terraform may want to recreate resources without a state move or `moved` block.

Solution hints:

- Terraform resource identity is the address, not just the remote EC2 instance ID.
- `count` addresses use numeric indexes.
- `for_each` addresses use keys.
- In production, use `moved` blocks or `terraform state mv` during refactors.

## Exercise 2: Add HTTPS with a dynamic ingress rule

Add an HTTPS rule to `ingress_rules`.

Tasks:

1. Add key `https`.
2. Set `from_port = 443`, `to_port = 443`, `protocol = "tcp"`.
3. Run `terraform plan` and find the generated nested ingress block.

Solution hints:

- You do not need to edit `main.tf` if the dynamic block is already driven by `var.ingress_rules`.
- Use a meaningful key because it becomes the rule description context in reviews.
- Dynamic blocks reduce copy-paste, but the resulting plan should still be easy to read.

## Exercise 3: Test lifecycle protection and sensitive output

Use the commented `prevent_destroy` example and the sensitive `admin_password` output.

Tasks:

1. Uncomment the lifecycle block in `aws_instance.server`.
2. Run `terraform plan -destroy` and observe the failure.
3. Re-comment the lifecycle block.
4. Run `terraform output` and then `terraform output -raw admin_password`.

Solution hints:

- `prevent_destroy` is evaluated during planning and blocks destructive plans.
- Sensitive outputs are hidden in normal output.
- Sensitive values can still be read intentionally and may still exist in state.
- Never use raw Terraform variables as your long-term production secret storage pattern.
