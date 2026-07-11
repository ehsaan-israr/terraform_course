# Exercises: Module 10 Advanced Terraform

## Exercise 1: Model services with complex types

Create a variable named `services` that accepts a map of service objects. Each service should include image, port, desired count, CPU, memory, environment variables, and optional secrets.

Deliverables:

- `variables.tf` with the typed variable and validation.
- `locals.tf` that derives enabled services.
- A short explanation of why `map(object(...))` is better than `any`.

## Exercise 2: Generate JSON safely

Write an IAM policy using `jsonencode` that grants read access to one S3 bucket and write access to a CloudWatch log group.

Review questions:

- What errors would be easier to make with a heredoc JSON string?
- How does Terraform preserve references inside `jsonencode`?

## Exercise 3: Import an existing bucket

Write an import block for an existing S3 bucket named `training-existing-bucket`.

Expected syntax:

```hcl
import {
  to = aws_s3_bucket.training
  id = "training-existing-bucket"
}
```

Deliverables:

- Resource block for the bucket.
- Import block.
- Notes describing how you would compare the plan before applying.

## Exercise 4: Refactor with moved blocks

Using `modules/10-advanced/project`, add a second EC2 instance to the monolith and then refactor it into the compute module.

Deliverables:

- Updated module interface.
- `moved` block for the new instance.
- Plan notes explaining why Terraform should not recreate the instance.
