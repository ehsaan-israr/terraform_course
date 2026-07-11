# Hardened Terraform Example

This directory remediates the insecure lab with safer Terraform patterns:

- References an existing AWS Secrets Manager secret by name.
- Restricts SSH to approved admin CIDRs.
- Enables S3 public access blocking, encryption, and versioning.
- Uses least-privilege IAM scoped to the required secret and bucket.

The example still uses placeholder values such as `vpc-00000000000000000`.
Replace them with sandbox values before running Terraform.

## Example commands

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan \
  -var='vpc_id=vpc-0123456789abcdef0' \
  -var='admin_cidrs=["203.0.113.10/32"]'
```

Prefer Session Manager over SSH for real production systems.

