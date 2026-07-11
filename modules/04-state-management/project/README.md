# Module 04 Project - Remote State Backend

This project teaches the standard AWS remote-state pattern:

```text
project/
  bootstrap/  -> creates S3 state bucket and DynamoDB lock table
  app/        -> stores its Terraform state in that remote backend
```

## Architecture

```text
+--------------------+       creates        +-----------------------------+
| bootstrap Terraform| -------------------> | S3 bucket for tfstate       |
| local state        |                      | DynamoDB table for locking  |
+--------------------+                      +-----------------------------+
                                                        ^
                                                        |
                                                        | backend "s3"
                                                        |
                                             +-----------------------------+
                                             | app Terraform configuration |
                                             | remote state + locking      |
                                             +-----------------------------+
```

## Step 1: Run the bootstrap stack

```bash
cd bootstrap
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

Save these outputs:

- `state_bucket_name`
- `lock_table_name`
- `backend_region`

## Step 2: Initialize the app backend

```bash
cd ../app
terraform init \
  -backend-config="bucket=<state_bucket_name>" \
  -backend-config="key=state-management/dev/terraform.tfstate" \
  -backend-config="region=<backend_region>" \
  -backend-config="dynamodb_table=<lock_table_name>" \
  -backend-config="encrypt=true"
```

The `key` is the object path inside the S3 bucket. In production, use a naming
scheme that includes application and environment, such as:

```text
network/prod/terraform.tfstate
payments/staging/terraform.tfstate
observability/dev/terraform.tfstate
```

## Step 3: Apply the app

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

Run a second terminal and try another apply while the first is running. The
DynamoDB table will prevent concurrent state writes.

## Step 4: Inspect state

```bash
terraform state list
terraform state show aws_s3_bucket.app_artifacts
terraform state pull > app-state.json
```

Delete the pulled state copy after inspection:

```bash
rm app-state.json
```

## Step 5: Practice migration

To practice local-to-remote migration:

1. Temporarily move `backend.tf` out of the app directory.
2. Run `terraform init` and `terraform apply`.
3. Move `backend.tf` back.
4. Run `terraform init -migrate-state` with backend config values.

Terraform will copy the local state into S3.

## Step 6: Cleanup

Destroy app resources first:

```bash
cd app
terraform destroy
```

Then destroy bootstrap resources if this is a disposable lab:

```bash
cd ../bootstrap
terraform destroy -var="force_destroy_state_bucket=true"
```

Production warning: state buckets are usually retained, versioned, and protected
from accidental deletion.

