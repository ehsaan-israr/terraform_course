# Module 08 Exercises: Terraform Security

## Exercise 1: Manual security review

Review `../project/insecure/main.tf` without running any scanner.

Find at least four issues:

- Secret management issue.
- Network exposure issue.
- Encryption issue.
- IAM least-privilege issue.

Deliverable:

- File/line reference for each issue.
- Business impact of each issue.
- Recommended remediation.

## Exercise 2: Scanner comparison

Run one or both tools:

```bash
checkov -d ../project/insecure
tfsec ../project/insecure
```

Deliverable:

- Which findings matched your manual review?
- Which findings were new?
- Which findings need human context before remediation?

## Exercise 3: Harden the configuration

Starting from `../project/insecure`, create your own fixed version before
looking at `../project/hardened`.

Requirements:

- No committed secret values.
- No public SSH.
- S3 encryption and public access block.
- IAM actions scoped to specific resources.

Deliverable:

- Short remediation checklist.
- Explanation of any remaining risk.

## Exercise 4: Incident response tabletop

A password in `terraform.tfvars` was committed and pushed.

Write the first five actions you take. Include:

- Rotation.
- Log and state search.
- Git history considerations.
- CI/CD changes.
- Prevention control.

## Interview drill

Answer in 2 minutes:

1. Does `sensitive = true` keep secrets out of state?
2. Why are Terraform state read permissions sensitive?
3. How would you separate Terraform plan and apply IAM permissions?

