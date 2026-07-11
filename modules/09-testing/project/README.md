# Terraform Testing Project

This project contains a simple S3 bucket module and the test tooling used in
Module 09.

## Layout

```text
project/
|-- modules/s3_bucket/
|-- test/terratest/s3_test.go
|-- scripts/validate.sh
|-- .tflint.hcl
`-- .github/workflows/validate.yml
```

## Static validation

Run from this directory:

```bash
./scripts/validate.sh
```

The script runs:

- `terraform fmt -check -recursive`
- `terraform init -backend=false`
- `terraform validate`
- `tflint --init` and `tflint --recursive` when TFLint is installed

## Terratest

Terratest creates a real S3 bucket, checks Terraform outputs, and destroys the
bucket at the end of the test.

Requirements:

- Go installed.
- Terraform installed.
- AWS credentials for a sandbox account.
- Permission to create and delete S3 buckets.

Run:

```bash
go test ./test/terratest -v -timeout 30m
```

The test generates a unique bucket name and sets `force_destroy = true` so
cleanup works even if test objects are added later.

