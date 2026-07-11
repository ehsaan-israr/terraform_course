# State Management App Stack

This stack is intentionally small. Its purpose is to demonstrate how an
application project stores state in the backend created by `../bootstrap`.

It creates one private, encrypted, versioned S3 bucket for sample application
artifacts. The important learning goal is the backend workflow, not the bucket
itself.

## Bootstrap then migrate workflow

1. Create backend resources:

   ```bash
   cd ../bootstrap
   terraform init
   terraform apply
   terraform output
   ```

2. Copy these output values:

   - `state_bucket_name`
   - `lock_table_name`
   - `backend_region`

3. Initialize this app with the remote backend:

   ```bash
   cd ../app
   terraform init \
     -backend-config="bucket=<state_bucket_name>" \
     -backend-config="key=state-management/dev/terraform.tfstate" \
     -backend-config="region=<backend_region>" \
     -backend-config="dynamodb_table=<lock_table_name>" \
     -backend-config="encrypt=true"
   ```

4. Apply the app:

   ```bash
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

5. Inspect state safely:

   ```bash
   terraform state list
   terraform state show aws_s3_bucket.app_artifacts
   terraform state pull > state-copy.json
   rm state-copy.json
   ```

## Migrating existing local state

If you first applied this app with local state, add `backend.tf` and run:

```bash
terraform init -migrate-state \
  -backend-config="bucket=<state_bucket_name>" \
  -backend-config="key=state-management/dev/terraform.tfstate" \
  -backend-config="region=<backend_region>" \
  -backend-config="dynamodb_table=<lock_table_name>" \
  -backend-config="encrypt=true"
```

Terraform will ask whether to copy the local state into S3. Confirm only after
you verify the bucket, key, region, and AWS account.

## Cleanup

Destroy the app stack before destroying the bootstrap stack:

```bash
terraform destroy
```

In real environments, do not delete backend buckets until state retention and
audit requirements have been satisfied.

