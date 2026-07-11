# Module 05 Exercises - Terraform Modules

Use the project in `../project` for these exercises. The goal is to practice
module interface design, composition, and safe refactoring.

## Exercise 1: Trace module dependencies

Draw the dependency graph from the root module:

- Which module creates the VPC?
- Which outputs are consumed by the security group module?
- Which outputs are consumed by ECS and RDS?

Success criteria: you can explain why the root module, not child modules, owns
cross-module wiring.

## Exercise 2: Add input validation

Update the VPC module so the number of public subnet CIDRs, private subnet CIDRs,
and availability zones match.

Hint:

```hcl
validation {
  condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
  error_message = "Provide one public subnet CIDR per availability zone."
}
```

Success criteria: invalid input fails during validation or planning with a clear
message.

## Exercise 3: Add a module output

Add `internet_gateway_id` to the VPC module outputs, then expose it from the root
module.

Success criteria: `terraform output` shows the internet gateway ID after apply.

## Exercise 4: Create a service module input

Add an `environment_variables` input to the ECS module and pass it into
`container_definitions`.

Success criteria: the task definition JSON includes the environment variables.

## Exercise 5: Refactor with `moved` blocks

Move one root-level resource into a child module in a separate lab
configuration. Add a `moved` block so Terraform updates state addresses without
replacing the AWS resource.

Success criteria: the plan shows a move and not a destroy/create.

## Exercise 6: Version a module

Copy the VPC module into a local Git repository, tag it `v1.0.0`, and call it
with:

```hcl
source = "git::https://example.com/your-org/terraform-aws-vpc.git?ref=v1.0.0"
```

Success criteria: you can explain how pinning protects production from
unexpected module changes.

## Exercise 7: Write module documentation

Write a README for `modules/security-groups` that documents:

- Purpose.
- Inputs.
- Outputs.
- Security assumptions.
- Example usage.

Success criteria: another student can use the module without reading every line
of source first.

