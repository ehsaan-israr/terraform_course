# Module 09: Testing Terraform

Terraform testing is how platform teams turn infrastructure changes into
repeatable engineering practice. The goal is not to prove that AWS works. The
goal is to catch mistakes early, document expected module behavior, and make
production changes safer.

## Learning objectives

By the end of this module you should be able to:

- Run `terraform fmt`, `init`, and `validate` as baseline checks.
- Use TFLint for Terraform and AWS provider linting.
- Explain static checks, plan checks, module tests, and integration tests.
- Write a Go Terratest test for a Terraform module.
- Design CI validation gates for pull requests and main-branch changes.
- Decide when to run real AWS integration tests and how to clean them up.

## Testing pyramid for Terraform

```text
                +---------------------------+
                | Production smoke checks   |
                +---------------------------+
              +-------------------------------+
              | AWS integration tests         |
              +-------------------------------+
            +-----------------------------------+
            | Module tests / Terratest          |
            +-----------------------------------+
          +---------------------------------------+
          | terraform validate / plan / scanners  |
          +---------------------------------------+
        +-------------------------------------------+
        | terraform fmt / TFLint / static analysis   |
        +-------------------------------------------+
```

Run the cheapest checks most often. Run expensive tests only where they add
confidence.

## Baseline Terraform checks

### terraform fmt

`terraform fmt` enforces canonical HCL formatting.

```bash
terraform fmt -recursive
terraform fmt -check -recursive
```

Use `-check` in CI so the job fails instead of rewriting files.

### terraform init

`terraform init` downloads providers and modules and configures the backend.

```bash
terraform init
terraform init -backend=false
```

For reusable modules, `-backend=false` is often enough because modules should
not configure backends. For live environments, production CI should initialize
the real backend so plans compare against real state.

### terraform validate

`terraform validate` checks syntax and provider schema rules after init.

```bash
terraform validate
terraform validate -json
```

Validation catches:

- Invalid HCL syntax.
- Wrong argument names.
- Missing required arguments.
- Type mismatches.
- Invalid references.

Validation does not catch:

- Every AWS runtime error.
- Organization policy violations.
- Broken assumptions in your module interface.
- Missing tags unless you test or enforce them.

## TFLint

TFLint provides Terraform linting and provider-specific rules.

Install and initialize plugins:

```bash
tflint --init
tflint --recursive
```

Example `.tflint.hcl`:

```hcl
plugin "aws" {
  enabled = true
  version = "0.48.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}
```

TFLint can catch:

- Missing required provider constraints.
- Deprecated Terraform syntax.
- Invalid AWS instance types or regions.
- Unused declarations.
- Provider-specific best-practice violations.

## Terraform native tests

Terraform includes native test support with `.tftest.hcl` files. These are
useful for checking module outputs, variable validation, and plan behavior.

Example:

```hcl
run "valid_bucket_name" {
  command = plan

  variables {
    bucket_name = "example-valid-bucket"
  }

  assert {
    condition     = output.bucket_name == "example-valid-bucket"
    error_message = "Bucket output should match input."
  }
}
```

Native tests are a good starting point. Terratest is still valuable when you
want the full power of Go, retries, AWS SDK assertions, and teardown logic.

## Terratest with Go

Terratest is a Go testing library for infrastructure. Since you already know
Go, think of Terratest as normal Go tests that call Terraform and optionally
query AWS.

Typical flow:

1. Copy or reference Terraform code.
2. Generate unique test names.
3. Run `terraform init` and `terraform apply`.
4. Assert outputs and AWS resource properties.
5. Run `terraform destroy` in `defer` cleanup.

### Go Terratest example

```go
package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestS3BucketModule(t *testing.T) {
	t.Parallel()

	awsRegion := "us-east-1"
	bucketName := fmt.Sprintf("terratest-example-%s", random.UniqueId())

	terraformOptions := &terraform.Options{
		TerraformDir: "../../modules/s3_bucket",
		Vars: map[string]interface{}{
			"bucket_name": bucketName,
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "Terratest",
			},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	outputName := terraform.Output(t, terraformOptions, "bucket_name")
	assert.Equal(t, bucketName, outputName)

	aws.AssertS3BucketExists(t, awsRegion, bucketName)
}
```

Testing guidance:

- Use unique resource names to avoid collisions.
- Keep tests parallel only when resources do not conflict.
- Always `defer terraform.Destroy`.
- Set timeouts for slow cloud resources.
- Isolate test AWS accounts from production.
- Budget for integration test cost.

## Module testing strategy

A reusable module should have a clear contract:

- Inputs.
- Outputs.
- Resources it owns.
- Defaults.
- Validation rules.
- Security expectations.

Recommended module checks:

1. `terraform fmt -check`.
2. `terraform init -backend=false`.
3. `terraform validate`.
4. TFLint.
5. Native Terraform tests for variable validation and outputs.
6. Terratest for real AWS behavior when the module creates important resources.

## Integration testing

Integration tests deploy real resources in a real AWS account. Use them when
you need to validate behavior that static checks cannot prove.

Good candidates:

- IAM policy can access only the intended bucket.
- ALB health checks route to an ECS service.
- RDS subnet group spans multiple AZs.
- S3 bucket encryption and public access block are actually configured.
- Lambda can read a secret and write logs.

Bad candidates:

- Every small formatting or variable change.
- Destructive tests in production accounts.
- Tests without reliable cleanup.
- Tests that require shared mutable resources without locks.

## Validation gates in CI

Pipeline diagram:

```text
Pull request opened
        |
        v
terraform fmt -check
        |
        v
terraform init -backend=false
        |
        v
terraform validate
        |
        v
tflint --recursive
        |
        v
security scan
        |
        v
module unit/native tests
        |
        v
terraform plan
        |
        v
review approval
        |
        v
merge
        |
        v
optional integration tests
        |
        v
apply with environment protection
```

Example GitHub Actions commands:

```yaml
- run: terraform fmt -check -recursive
- run: terraform init -backend=false
- run: terraform validate
- run: tflint --init
- run: tflint --recursive
- run: go test ./test/terratest -v -timeout 30m
```

## Plan testing and review

Plans are test artifacts. Review them carefully.

Look for:

- Unexpected destroys.
- Resource replacements.
- Public access changes.
- IAM policy expansion.
- Encryption changes.
- Tag removal.
- Provider drift.
- Changes outside the pull request's intent.

For automation, convert plans to JSON:

```bash
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
```

The JSON can be checked by OPA, Conftest, custom scripts, or cost tools.

## Interview Q&A

**Q: What is the difference between `terraform validate` and `terraform plan`?**  
A: `validate` checks configuration syntax and provider schema locally after
init. `plan` compares configuration with state and provider data to propose
real changes.

**Q: Why use TFLint if Terraform already validates configuration?**  
A: TFLint catches style, best-practice, and provider-specific issues that
Terraform validation does not, such as invalid instance types or missing
required provider constraints.

**Q: How do you test Terraform modules?**  
A: Start with fmt, validate, and lint. Add native Terraform tests for module
contracts. Use Terratest or integration tests for real AWS behavior and critical
modules.

**Q: How do you prevent Terratest from leaving resources behind?**  
A: Use unique names, `defer terraform.Destroy`, timeouts, isolated test
accounts, tagging, and scheduled cleanup jobs that remove stale test resources.

**Q: Should every pull request run integration tests?**  
A: Not always. Expensive tests can run nightly, on release branches, or when
module paths change. Critical shared modules may justify PR integration tests.

## Case study: Untested module breaks production deploys

### Situation

A platform team maintained an internal S3 bucket module. A developer added
versioning and changed an output from:

```hcl
output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}
```

to:

```hcl
output "bucket_id" {
  value = aws_s3_bucket.this.id
}
```

No tests covered the module contract. Downstream application stacks still
expected `module.artifacts.bucket_name`, so production plans failed during a
release window.

### Root causes

- No module contract tests.
- No downstream example stack in CI.
- Review focused on resources, not outputs.
- Production release depended on a shared module change.

### Remediation

1. Restore the `bucket_name` output.
2. Add native tests for expected outputs.
3. Add Terratest to create a bucket and verify encryption/versioning.
4. Add semantic versioning for shared modules.
5. Require release notes for module interface changes.
6. Run downstream example plans in CI before publishing module versions.

The team learned that Terraform modules are APIs. Outputs and variable names
deserve the same compatibility discipline as Go function signatures.

## Mini project: Test an S3 bucket module

Use `project/`.

1. Review the `modules/s3_bucket` module.
2. Run `scripts/validate.sh`.
3. Initialize TFLint with `tflint --init`.
4. Run the Go Terratest suite from `test/terratest`.
5. Add one more assertion for versioning or encryption.
6. Explain which checks are static and which require AWS credentials.

