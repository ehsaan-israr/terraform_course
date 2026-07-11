# Backend Bootstrap Stack

This stack creates the AWS resources required for an S3 Terraform backend:

- S3 bucket for state storage.
- S3 versioning for recovery.
- Server-side encryption.
- Public access block.
- Bucket owner enforced object ownership.
- DynamoDB table for state locking.

## Why this stack uses local state

The backend bucket must exist before another Terraform configuration can use it.
Run this bootstrap stack first with local state. In production, keep this state
file in a secure location or migrate it into a separate administrative backend.

## Commands

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

Copy the values from `state_bucket_name`, `lock_table_name`, and
`backend_region` into the app stack's `terraform init -backend-config` command.

## Cleanup

State buckets often contain versioned objects and should not be destroyed in real
accounts. For lab accounts only, you can set:

```bash
terraform apply -var="force_destroy_state_bucket=true"
terraform destroy -var="force_destroy_state_bucket=true"
```

