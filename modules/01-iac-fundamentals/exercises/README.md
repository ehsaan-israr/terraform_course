# Module 1 Exercises - Solution Hints

These exercises are designed to make you read Terraform output carefully. Do them in a sandbox AWS account, then destroy resources when finished.

## Exercise 1: Read a plan like a change ticket

Create one S3 bucket with tags, then run `terraform plan`.

Tasks:

1. Identify every resource Terraform plans to create.
2. Find attributes marked `(known after apply)`.
3. Explain why Terraform cannot know those values before calling AWS.

Solution hints:

- Bucket ARNs and regional domain names are computed by the AWS provider.
- Tags are usually known before apply because you declared them.
- The plan is a contract for intent, but provider-computed values appear only after AWS responds.

## Exercise 2: Modify EC2 safely

Apply the Module 1 project, then change `instance_type`.

Tasks:

1. Run `terraform plan`.
2. Determine whether Terraform updates the instance in place or replaces it.
3. Explain what the plan means for uptime.

Solution hints:

- Look for `~` for in-place updates and `-/+` for replacement.
- Some EC2 changes can happen in place, but may still require stop/start behavior on AWS.
- In production, treat compute shape changes as user-impacting unless protected by a load balancer or rolling deployment pattern.

## Exercise 3: Observe drift

Apply the project, then manually change the EC2 `Name` tag in the AWS Console.

Tasks:

1. Run `terraform plan`.
2. Find the proposed tag change.
3. Decide whether to keep the manual change by updating code or revert it by applying Terraform.

Solution hints:

- Terraform refreshes remote object data during planning.
- Drift is not automatically bad; it is a signal that reality and code differ.
- The durable fix is to make the source of truth clear. Either encode the desired value in Terraform or stop managing that attribute.
