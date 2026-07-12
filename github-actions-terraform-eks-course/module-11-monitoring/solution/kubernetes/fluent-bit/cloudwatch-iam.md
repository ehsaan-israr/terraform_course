# Fluent Bit IRSA — IAM Setup

Replace `ACCOUNT_ID`, `CLUSTER_NAME`, and OIDC provider ID.

## 1. Trust Policy (IAM Role)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/OIDC_ID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-east-1.amazonaws.com/id/OIDC_ID:sub": "system:serviceaccount:amazon-cloudwatch:fluent-bit",
          "oidc.eks.us-east-1.amazonaws.com/id/OIDC_ID:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

## 2. Permissions Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:us-east-1:ACCOUNT_ID:log-group:/aws/eks/*"
    }
  ]
}
```

## 3. Annotate ServiceAccount

Update `fluent-bit-config.yaml`:

```yaml
eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/gha-terraform-eks-fluent-bit
```

## 4. Verify

```bash
kubectl logs -n amazon-cloudwatch -l app=fluent-bit --tail=20
aws logs describe-log-groups --log-group-name-prefix /aws/eks/gha-terraform-eks
```
