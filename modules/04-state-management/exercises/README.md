# Module 04 Exercises - State Management

These exercises reinforce the state workflows used by production Terraform
teams. Use a sandbox AWS account and unique names.

## Exercise 1: Read state without editing it

1. Apply the sample app in `../project/app`.
2. Run:

   ```bash
   terraform state list
   terraform state show aws_s3_bucket.app_artifacts
   terraform state pull > state.json
   ```

3. Identify the bucket name, ARN, provider address, and resource address.
4. Delete `state.json` after inspection.

Success criteria: you can explain the difference between a resource address and
an AWS resource ID.

## Exercise 2: Use a `moved` block

1. Rename `aws_s3_bucket.app_artifacts` to `aws_s3_bucket.artifacts`.
2. Add:

   ```hcl
   moved {
     from = aws_s3_bucket.app_artifacts
     to   = aws_s3_bucket.artifacts
   }
   ```

3. Run `terraform plan`.

Success criteria: Terraform reports a state move rather than a bucket
replacement.

## Exercise 3: Practice `terraform state mv`

Repeat Exercise 2 without a `moved` block:

```bash
terraform state mv aws_s3_bucket.app_artifacts aws_s3_bucket.artifacts
terraform plan
```

Success criteria: the plan does not destroy and recreate the bucket.

## Exercise 4: Import an unmanaged bucket

1. Create a bucket outside Terraform.
2. Add a matching `aws_s3_bucket` resource block.
3. Run:

   ```bash
   terraform import aws_s3_bucket.imported <bucket-name>
   terraform plan
   ```

4. Add versioning, encryption, and public access resources as needed.

Success criteria: Terraform manages the bucket without replacing it.

## Exercise 5: Recover from a bad state edit

In a lab environment:

1. Pull state to a backup file.
2. Move a resource to the wrong address with `terraform state mv`.
3. Observe the plan.
4. Move it back or restore the previous S3 object version.

Success criteria: you can repair state without changing real infrastructure.

## Exercise 6: Drift detection pipeline

Write a shell step for CI:

```bash
terraform init -input=false
terraform plan -detailed-exitcode -input=false -no-color
```

Document how your pipeline should treat exit codes `0`, `1`, and `2`.

Success criteria: drift creates a visible alert but does not automatically apply
changes without review.

