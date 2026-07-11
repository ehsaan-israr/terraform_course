# Bootstrap Stack — S3 State Bucket + DynamoDB Lock Table

## Starting point and purpose

This is the **first root** in the Module 4 project. It creates the AWS infrastructure that other Terraform stacks use for remote state: an S3 bucket and a DynamoDB lock table.

It intentionally uses **local state** (chicken-and-egg: the backend must exist before the app stack can reference it).

---

## File index

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform `>= 1.5.0`; AWS and random providers. |
| `providers.tf` | AWS provider configuration. |
| `variables.tf` | Region, name prefix, environment, `force_destroy_state_bucket`, tags. |
| `main.tf` | S3 state bucket, DynamoDB lock table, encryption, versioning, public access block. |
| `outputs.tf` | Bucket name, lock table name, region, example backend init command. |
| `README.md` | This file. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources |
|---------|-------------------|---------------|
| **State storage** | `main.tf` | `aws_s3_bucket.terraform_state` |
| **Bucket hardening** | `main.tf` | Versioning, SSE, public access block, ownership controls |
| **State locking** | `main.tf` | `aws_dynamodb_table.terraform_locks` |
| **Unique naming** | `main.tf` | `random_id.suffix` + account ID |

---

## Run

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

Save the outputs — you need them to initialize the `app/` stack.

---

## Cleanup

Destroy the app stack first, then:

```bash
terraform apply -var="force_destroy_state_bucket=true"
terraform destroy
```

Without `force_destroy_state_bucket=true`, the versioned state bucket cannot be emptied.
