# Module 09 Exercises: Testing Terraform

## Exercise 1: Run static validation

From `../project`, run:

```bash
./scripts/validate.sh
```

Deliverable:

- Command output.
- Any tool you had to install.
- One issue static validation can catch.
- One issue static validation cannot catch.

## Exercise 2: Inspect the S3 module contract

Review `../project/modules/s3_bucket`.

Deliverable:

- List all inputs and outputs.
- Identify which defaults are test-friendly.
- Explain why `force_destroy` defaults to `false` even though tests set it to
  `true`.

## Exercise 3: Extend the Terratest suite

Add one assertion to `../project/test/terratest/s3_test.go`.

Ideas:

- Assert the bucket ARN contains the bucket name.
- Assert versioning is `Enabled`.
- Assert encryption is `AES256`.

Deliverable:

- Test change.
- `go test ./test/terratest -v -timeout 30m` output from a sandbox AWS account.

## Exercise 4: Design validation gates

Create a CI gate design for a production Terraform repository.

Include:

- Checks that run on every pull request.
- Checks that run only on main.
- Checks that require AWS credentials.
- Checks that should block production apply.

## Interview drill

Answer in 2 minutes:

1. What is the difference between `validate` and `plan`?
2. When should Terratest run in CI?
3. How do you avoid leaked resources from failed integration tests?

