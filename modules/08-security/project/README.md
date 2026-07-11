# Security Remediation Lab

This lab compares intentionally insecure Terraform with a hardened version.
Do not apply the insecure configuration to a real AWS account.

## Structure

```text
project/
|-- insecure/
|   |-- README.md
|   `-- main.tf
|-- hardened/
|   |-- README.md
|   |-- main.tf
|   `-- variables.tf
`-- .checkov.yaml
```

## Remediation checklist

| Risk | Insecure pattern | Hardened pattern |
| --- | --- | --- |
| Secret exposure | Password hardcoded in Terraform | Reference AWS Secrets Manager by name/ARN |
| Network exposure | SSH open to `0.0.0.0/0` | Restrict admin CIDRs or use SSM Session Manager |
| Data exposure | S3 bucket without encryption/public access block | Encryption, versioning, public access block |
| Privilege escalation | IAM `Action = "*", Resource = "*"` | Specific actions and resource ARNs |

## Suggested scanner commands

```bash
checkov -d insecure
tfsec insecure

checkov -d hardened
tfsec hardened
```

Expected result: scanners should flag multiple findings in `insecure/`. The
`hardened/` version demonstrates safer patterns, but you should still adapt it
to your organization's exact policies.

## Student tasks

1. Identify every insecure pattern before opening the hardened example.
2. Run Checkov or tfsec and compare scanner output with your manual review.
3. Explain which issues might still appear in Terraform state.
4. Write a pull request summary that explains the business risk and technical
   remediation.

