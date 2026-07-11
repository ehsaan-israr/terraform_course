# WARNING: Intentionally Insecure Terraform

This directory is a teaching aid. It intentionally includes dangerous patterns:

- Hardcoded database password.
- SSH open to the internet.
- S3 bucket without encryption or public access controls.
- IAM policy with `Action = "*"` and `Resource = "*"`.

Do not apply this configuration in any AWS account. Use it only for reading,
code review practice, and scanner demonstrations.

