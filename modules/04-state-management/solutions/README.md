# Module 4 Solutions - State Management

These answers correspond to `../exercises/README.md`. State operations are
powerful; practice in a lab account before using them on shared infrastructure.

## Exercise 1: Read state without editing it

Apply the app project:

```bash
cd modules/04-state-management/project/app
terraform init
terraform apply
```

Inspect state:

```bash
terraform state list
terraform state show aws_s3_bucket.app_artifacts
terraform state pull > state.json
```

Expected managed addresses include:

```text
aws_s3_bucket.app_artifacts
aws_s3_bucket_public_access_block.app_artifacts
aws_s3_bucket_server_side_encryption_configuration.app_artifacts
aws_s3_bucket_versioning.app_artifacts
```

In `terraform state show aws_s3_bucket.app_artifacts`, identify:

- Resource address: `aws_s3_bucket.app_artifacts`
- AWS resource ID: the S3 bucket name, such as
  `state-demo-dev-123456789012`
- ARN: `arn:aws:s3:::state-demo-dev-123456789012`
- Provider address in `state.json`: typically something like
  `provider["registry.terraform.io/hashicorp/aws"]`

The resource address is Terraform's internal pointer to an object in the
configuration and state. The AWS resource ID is the provider's remote object ID.
They are related, but not interchangeable.

Remove the local state export after inspection:

```bash
rm state.json
```

## Exercise 2: Use a `moved` block

Rename the S3 bucket resource in `project/app/main.tf`:

```hcl
moved {
  from = aws_s3_bucket.app_artifacts
  to   = aws_s3_bucket.artifacts
}

resource "aws_s3_bucket" "artifacts" {
  bucket = local.bucket_name

  tags = merge(local.tags, {
    Name = local.bucket_name
  })
}
```

Update references in the same file:

```hcl
resource "aws_s3_bucket_public_access_block" "app_artifacts" {
  bucket = aws_s3_bucket.artifacts.id
}

resource "aws_s3_bucket_versioning" "app_artifacts" {
  bucket = aws_s3_bucket.artifacts.id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_artifacts" {
  bucket = aws_s3_bucket.artifacts.id
}
```

Update outputs:

```hcl
output "artifact_bucket_name" {
  description = "Name of the sample application artifact bucket."
  value       = aws_s3_bucket.artifacts.bucket
}

output "artifact_bucket_arn" {
  description = "ARN of the sample application artifact bucket."
  value       = aws_s3_bucket.artifacts.arn
}
```

Run:

```bash
terraform plan
```

The success signal is a move, not a replacement:

```text
# aws_s3_bucket.app_artifacts has moved to aws_s3_bucket.artifacts
```

No S3 bucket should be destroyed or recreated.

## Exercise 3: Practice `terraform state mv`

Repeat the same rename without a `moved` block.

First change the resource name and references in code from
`aws_s3_bucket.app_artifacts` to `aws_s3_bucket.artifacts`. Then move the state
address manually:

```bash
terraform state mv aws_s3_bucket.app_artifacts aws_s3_bucket.artifacts
terraform plan
```

If the state move is correct, Terraform should not propose destroying and
recreating the bucket. The remote bucket ID is unchanged; only Terraform's
address for that object changed.

When choosing between the two approaches:

- Prefer `moved` blocks for code-reviewed refactors because the migration is
  documented in configuration and repeatable.
- Use `terraform state mv` for one-time emergency repairs or older Terraform
  versions.

## Exercise 4: Import an unmanaged bucket

Create an S3 bucket outside Terraform, then add a matching resource block:

```hcl
resource "aws_s3_bucket" "imported" {
  bucket = "replace-with-your-existing-bucket-name"

  tags = merge(local.tags, {
    Name = "replace-with-your-existing-bucket-name"
  })
}
```

Import it:

```bash
terraform import aws_s3_bucket.imported replace-with-your-existing-bucket-name
terraform plan
```

If the plan wants to replace the bucket, stop and correct the configuration.
Import should connect Terraform to the existing object, not create a new one.

Add companion resources to manage important settings:

```hcl
resource "aws_s3_bucket_public_access_block" "imported" {
  bucket = aws_s3_bucket.imported.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "imported" {
  bucket = aws_s3_bucket.imported.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "imported" {
  bucket = aws_s3_bucket.imported.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

Each companion resource may need its own import if the setting already exists
remotely. Use `terraform plan` after each step and reconcile differences in
code.

## Exercise 5: Recover from a bad state edit

A safe lab flow:

```bash
terraform state pull > state-backup.json
terraform state mv aws_s3_bucket.app_artifacts aws_s3_bucket.wrong_name
terraform plan
```

The plan should reveal the mistake by showing the expected address missing and a
new address present. Repair the address:

```bash
terraform state mv aws_s3_bucket.wrong_name aws_s3_bucket.app_artifacts
terraform plan
```

If you use the remote S3 backend from `project/bootstrap`, recovery can also use
S3 object versioning:

1. Find the previous version of the state object in the backend bucket.
2. Restore it according to your team's runbook.
3. Run `terraform plan` to verify Terraform and AWS reality are aligned.

Do not hand-edit state JSON unless directed by an experienced operator and after
taking a backup. Prefer CLI state commands because they preserve state structure.

## Exercise 6: Drift detection pipeline

Use this CI step:

```bash
terraform init -input=false
terraform plan -detailed-exitcode -input=false -no-color
```

Exit-code handling:

| Exit code | Meaning | Pipeline behavior |
| --- | --- | --- |
| `0` | Plan succeeded and no changes are needed. | Mark the drift check green. |
| `1` | Terraform failed to plan. | Fail the job and require investigation. |
| `2` | Plan succeeded and changes are present. | Mark drift as detected; notify owners, but do not auto-apply. |

Example shell wrapper:

```bash
set +e
terraform plan -detailed-exitcode -input=false -no-color
status=$?
set -e

case "$status" in
  0)
    echo "No drift detected."
    ;;
  1)
    echo "Terraform plan failed." >&2
    exit 1
    ;;
  2)
    echo "Drift or unapplied changes detected. Review the plan."
    exit 0
    ;;
  *)
    echo "Unexpected Terraform exit code: $status" >&2
    exit "$status"
    ;;
esac
```

Some teams choose to exit non-zero on drift (`2`) to make dashboards red. That
is fine if it creates a review workflow, but the important production rule is
the same: detection should alert humans, not automatically apply changes.
