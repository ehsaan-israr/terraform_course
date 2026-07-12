# AWS Authentication for GitHub Actions — Module 07

This guide covers **OIDC (recommended)** and **access keys (alternative)** for pushing Docker images to Amazon ECR in `us-east-1`.

---

## Option A — OIDC (Recommended)

### 1. Create IAM OIDC provider (one-time per account)

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

If the provider already exists, skip this step.

### 2. Create IAM policy for ECR push

Save as `ecr-push-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAuth",
      "Effect": "Allow",
      "Action": ["ecr:GetAuthorizationToken"],
      "Resource": "*"
    },
    {
      "Sid": "ECRPush",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:DescribeImages"
      ],
      "Resource": "arn:aws:ecr:us-east-1:ACCOUNT_ID:repository/course-api"
    }
  ]
}
```

Replace `ACCOUNT_ID` with your AWS account ID.

```bash
aws iam create-policy \
  --policy-name github-actions-ecr-push \
  --policy-document file://ecr-push-policy.json
```

### 3. Create IAM role with trust policy

Save as `trust-policy.json` (replace `ORG`, `REPO`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:ORG/REPO:*"
        }
      }
    }
  ]
}
```

Tighten `sub` for production:

```text
repo:ORG/REPO:ref:refs/heads/main
```

```bash
aws iam create-role \
  --role-name github-actions-ecr-role \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
  --role-name github-actions-ecr-role \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/github-actions-ecr-push
```

### 4. GitHub repository configuration

| Name | Type | Value |
| --- | --- | --- |
| `AWS_ROLE_ARN` | Secret | `arn:aws:iam::ACCOUNT_ID:role/github-actions-ecr-role` |
| `AWS_REGION` | Variable | `us-east-1` |

### 5. Workflow requirements

```yaml
permissions:
  id-token: write

- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: us-east-1
```

---

## Option B — Access Keys (Alternative, Not Recommended)

Use only for isolated sandboxes when OIDC setup is not possible.

### 1. Create IAM user with programmatic access

Attach the same ECR push policy (narrow scope — ECR only, not `AdministratorAccess`).

### 2. GitHub secrets

| Name | Value |
| --- | --- |
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |

### 3. Workflow change

Replace the OIDC `configure-aws-credentials` step with:

```yaml
- name: Configure AWS credentials (access keys — lab only)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-east-1
```

**Risks:** long-lived credentials, manual rotation, broader blast radius if leaked.

---

## Create ECR Repository

```bash
aws ecr create-repository \
  --repository-name course-api \
  --image-scanning-configuration scanOnPush=true \
  --region us-east-1
```

---

## Verify

After a successful CI run:

```bash
aws ecr describe-images \
  --repository-name course-api \
  --region us-east-1
```
