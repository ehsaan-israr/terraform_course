# Module 08: Terraform Security for AWS

Security in Terraform is a combination of good AWS design, careful state
handling, code review, scanning, and policy enforcement. Terraform can create
secure infrastructure repeatably, but it can also repeat security mistakes at
enterprise scale.

## Learning objectives

By the end of this module you should be able to:

- Keep secrets out of Git and reduce their exposure in Terraform state.
- Apply least privilege IAM patterns in Terraform.
- Enable encryption for common AWS resources.
- Identify insecure network patterns before they reach production.
- Use tools such as tfsec, Checkov, TFLint, and policy-as-code gates.
- Explain OPA and Sentinel concepts at an interview level.
- Remediate an incident caused by hardcoded secrets in committed tfvars files.

## Security mindset for Terraform

Terraform is a privileged automation system. If Terraform can create IAM roles,
security groups, KMS keys, and databases, then the Terraform execution role is a
high-value target.

Production controls should protect:

- **Source code:** no secrets, mandatory review, branch protection.
- **State:** encrypted remote backend, restricted IAM, state locking.
- **Execution:** short-lived credentials, OIDC, least privilege CI roles.
- **Plans:** scanned for policy violations and risky changes.
- **Runtime resources:** encryption, private networking, logging, and tagging.

## Secrets management

### Do not commit secrets

Never put secrets in:

- `terraform.tfvars`
- `*.auto.tfvars`
- `locals`
- provider blocks
- user data scripts
- GitHub Actions workflow environment variables

### BEFORE: insecure secret in tfvars

```hcl
# terraform.tfvars
db_username = "admin"
db_password = "SuperSecretPassword123!"
```

Problems:

- The secret is committed to Git history.
- Pull request reviewers and CI logs may expose it.
- Even if deleted later, it remains in history.
- It may also be written to Terraform state if used in a resource argument.

### AFTER: retrieve secret metadata from AWS Secrets Manager

```hcl
data "aws_secretsmanager_secret" "db" {
  name = "prod/payments/db"
}

data "aws_secretsmanager_secret_version" "db" {
  secret_id = data.aws_secretsmanager_secret.db.id
}

locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)
}
```

This is better than committing secrets, but still be careful: if you pass
`local.db_credentials.password` into a Terraform-managed resource argument, it
can appear in state. Prefer AWS services that reference secrets by ARN when
possible.

### Safer pattern: pass secret ARNs, not secret values

```hcl
resource "aws_ecs_task_definition" "api" {
  family                   = "payments-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name  = "api"
      image = "public.ecr.aws/nginx/nginx:latest"
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = data.aws_secretsmanager_secret.db.arn
        }
      ]
    }
  ])
}
```

## Least privilege IAM

IAM policies should allow only the actions, resources, and conditions required.

### BEFORE: administrator-style wildcard

```hcl
resource "aws_iam_policy" "bad" {
  name = "bad-app-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}
```

### AFTER: scoped S3 read access

```hcl
resource "aws_iam_policy" "good" {
  name = "payments-read-artifacts"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      }
    ]
  })
}
```

Least privilege checklist:

- Use task-specific IAM roles.
- Avoid `Action = "*"` and `Resource = "*"`.
- Add resource ARNs when services support them.
- Add conditions such as `aws:PrincipalArn`, `aws:SourceVpce`, or
  `kms:ViaService` when appropriate.
- Separate CI plan permissions from apply permissions.

## Encryption

Encryption should be explicit. Many AWS services have improved defaults, but
production Terraform should still document the intended control.

### BEFORE: unencrypted S3 bucket

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "example-logs"
}
```

### AFTER: encrypted, private, versioned bucket

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "example-logs-secure"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

Encryption examples:

- S3: server-side encryption with SSE-S3 or SSE-KMS.
- EBS: account-level encryption by default and explicit encrypted volumes.
- RDS: `storage_encrypted = true`.
- CloudWatch Logs: KMS key where required.
- Terraform state backend: S3 encryption and restricted bucket policy.

## Network security

### BEFORE: open SSH

```hcl
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
}
```

### AFTER: restricted admin access

```hcl
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidrs
  security_group_id = aws_security_group.app.id
}
```

Better yet, avoid SSH entirely by using AWS Systems Manager Session Manager,
immutable images, and deployment automation.

## Security scanning

Scanning catches known insecure patterns before apply.

### tfsec

```bash
tfsec .
tfsec --minimum-severity HIGH .
```

tfsec checks Terraform for common cloud misconfigurations such as public S3,
unencrypted storage, and open security group rules.

### Checkov

```bash
checkov -d .
checkov -d . --framework terraform
```

Checkov includes Terraform, Kubernetes, Dockerfile, GitHub Actions, and other
policy checks. It can output SARIF for code scanning dashboards.

### TFLint

```bash
tflint --init
tflint --recursive
```

TFLint focuses on Terraform quality, provider-specific linting, deprecated
arguments, invalid instance types, and naming patterns.

## Policy as Code

Policy as Code turns security and compliance requirements into executable
rules.

### OPA concepts

Open Policy Agent (OPA) evaluates policies written in Rego against JSON input.
Terraform plans can be converted to JSON:

```bash
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
opa eval --data policy.rego --input tfplan.json "data.terraform.deny"
```

Example policy intent:

```rego
package terraform

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_security_group_rule"
  resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
  resource.change.after.from_port == 22
  msg := "SSH must not be open to the internet"
}
```

### Sentinel concepts

Sentinel is HashiCorp's policy-as-code framework used with Terraform Cloud and
Terraform Enterprise. Policies can be advisory, soft mandatory, or hard
mandatory.

Common policy examples:

- Deny public S3 buckets.
- Require cost center and owner tags.
- Require RDS encryption.
- Restrict instance families.
- Require production changes to use approved workspaces.

## Secure CI/CD

Secure Terraform automation uses short-lived credentials:

```text
GitHub Actions
    |
    | OIDC token
    v
AWS IAM role with trust policy
    |
    | limited plan/apply permissions
    v
Terraform resources
```

Avoid:

- Long-lived AWS access keys in GitHub secrets.
- One CI role with administrator access to every account.
- Unprotected production apply workflows.
- Printing sensitive outputs in CI logs.

## Interview Q&A

**Q: Is marking a Terraform variable `sensitive = true` enough to protect a secret?**  
A: No. It hides the value from normal CLI output, but the value may still be in
state. Keep secrets out of Terraform when possible, or pass secret references
such as ARNs.

**Q: How do you secure Terraform state?**  
A: Store state remotely in an encrypted S3 bucket, enable versioning, restrict
access with IAM and bucket policy, use DynamoDB locking, and avoid broad read
permissions because state can contain sensitive data.

**Q: What is least privilege for Terraform execution?**  
A: The execution role should have only the permissions required for the stack it
manages. Many teams separate read-only plan roles from write-capable apply
roles, and separate roles by account/environment.

**Q: What should a scanner block before apply?**  
A: High-risk issues such as public administrative ports, public S3 buckets,
unencrypted databases, wildcard IAM, disabled logging, missing required tags,
and policy violations defined by the organization.

**Q: How do OPA and Sentinel differ?**  
A: OPA is a general-purpose open-source policy engine using Rego. Sentinel is
HashiCorp's policy framework integrated with Terraform Cloud and Enterprise.
Both can evaluate infrastructure policy, but they differ in ecosystem and
runtime.

## Case study: Breach via committed tfvars secret

### Incident

A developer created a quick database proof of concept and committed:

```hcl
db_password = "Winter2026!"
```

The file landed in a feature branch and was pushed to the central Git remote.
Several weeks later, the branch was deleted, but the secret remained in Git
history and had been copied into CI logs during a failed plan.

### Impact

- The database password was exposed to anyone with repository access.
- The password was reused in staging and production.
- Incident responders had to assume the credential was compromised.
- Customer-facing release work paused while secrets were rotated.

### Response

1. Revoke and rotate the database password immediately.
2. Search logs, state files, and Git history for the exposed value.
3. Invalidate derived credentials and sessions.
4. Move the secret to AWS Secrets Manager.
5. Update applications to reference the secret by ARN.
6. Add secret scanning to pull requests and pushes.
7. Add a policy that blocks `*.tfvars` files containing password-like keys.
8. Train developers on Terraform state sensitivity.

### Long-term fixes

- Pre-commit secret scanning.
- GitHub secret scanning and push protection.
- CI checks for Checkov/tfsec.
- Mandatory review for IAM, networking, and secrets changes.
- Separate Dev/Staging/Prod credentials.
- No shared passwords across environments.

## Mini project: Remediate insecure Terraform

Use `project/insecure` and `project/hardened`.

1. Review the insecure Terraform and identify:
   - Hardcoded secret.
   - Open SSH security group rule.
   - Unencrypted S3 bucket.
   - Wildcard IAM policy.
2. Run a scanner such as:

   ```bash
   checkov -d project/insecure
   tfsec project/insecure
   ```

3. Compare with `project/hardened`.
4. Document the remediation steps in a pull request summary.
5. Explain which issues are prevented by code review, scanning, IAM, and AWS
   runtime controls.

