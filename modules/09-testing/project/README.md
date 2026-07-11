# Module 9 Project — Terraform Testing and Validation Pipeline

## Starting point and purpose

This project demonstrates **Terraform testing at two levels**: static validation (fmt, validate, TFLint) and integration testing (Terratest against real AWS). It centers on a reusable **S3 bucket module** with security defaults.

**Learning goals:** module testing, static analysis in CI, Terratest integration tests, and validation scripting.

---

## Architecture

```text
modules/s3_bucket/          <-- module under test
test/terratest/s3_test.go   <-- integration tests (real AWS)
scripts/validate.sh         <-- local static validation
.github/workflows/validate.yml  <-- CI pipeline
```

---

## File index

### Project root

| File | Purpose |
|------|---------|
| `README.md` | This file — layout, validation and Terratest instructions. |
| `go.mod` / `go.sum` | Go module with Terratest and testify dependencies. |
| `.tflint.hcl` | TFLint rules (AWS plugin, documented vars/outputs, required providers). |

### `modules/s3_bucket/` — Module under test

| File | Purpose |
|------|---------|
| `main.tf` | S3 bucket + public access block + encryption + versioning. |
| `variables.tf` | Bucket name, force_destroy, versioning, optional KMS, tags. |
| `outputs.tf` | Bucket name/ARN, versioning status, encryption algorithm. |

### `test/terratest/`

| File | Purpose |
|------|---------|
| `s3_test.go` | Creates bucket via Terraform, asserts outputs, verifies existence, destroys. |

### `scripts/`

| File | Purpose |
|------|---------|
| `validate.sh` | Runs fmt, init, validate, optional TFLint. |

### CI

| File | Purpose |
|------|---------|
| `.github/workflows/validate.yml` | Static validation on PR; Terratest on push to `main`. |

---

## Feature → file mapping

| Feature | Contributing files | Key resources / behavior |
|---------|-------------------|--------------------------|
| **Secure S3 module** | `modules/s3_bucket/*` | `aws_s3_bucket.this` + PAB + SSE + versioning |
| **Input validation** | `modules/s3_bucket/variables.tf` | Bucket name length validation |
| **Optional KMS encryption** | `modules/s3_bucket/main.tf` | `kms_key_id` variable |
| **Static validation pipeline** | `scripts/validate.sh`, `.tflint.hcl`, `.github/workflows/validate.yml` | fmt, validate, TFLint |
| **Integration testing** | `test/terratest/s3_test.go`, `go.mod` | Real AWS apply + assert + destroy |
| **Test cleanup** | `s3_test.go` | `force_destroy = true`, `defer terraform.Destroy` |

---

## Run

### Static validation

```bash
./scripts/validate.sh
```

### Terratest (requires Go, Terraform, AWS credentials)

```bash
go test ./test/terratest -v -timeout 30m
```

---

## Student tasks

1. Add a TFLint rule and confirm `validate.sh` catches a deliberate violation.
2. Write a second Terratest case for the KMS encryption path.
3. Add a `terraform test` unit test (Terraform 1.6+) alongside Terratest.
