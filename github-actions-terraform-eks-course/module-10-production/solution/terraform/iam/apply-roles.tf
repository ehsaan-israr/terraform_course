resource "aws_iam_role" "terraform_apply" {
  name               = "${var.project_name}-terraform-apply-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json

  tags = {
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "apply_policy" {
  statement {
    sid    = "StateRW"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.state_bucket_name}",
      "arn:aws:s3:::${var.state_bucket_name}/${var.environment}/*"
    ]
  }

  statement {
    sid    = "StateLock"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.lock_table_name}"]
  }

  statement {
    sid    = "ManageTaggedResources"
    effect = "Allow"
    actions = [
      "ec2:*",
      "eks:*",
      "ecr:*",
      "ssm:*",
      "logs:*"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = [var.environment]
    }
  }

  statement {
    sid    = "CreateWithTag"
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateVpc",
      "eks:CreateCluster",
      "ecr:CreateRepository",
      "ssm:PutParameter"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = [var.environment]
    }
  }

  statement {
    sid    = "PassRoleToEKS"
    effect = "Allow"
    actions = ["iam:PassRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "terraform_apply" {
  name   = "apply-${var.environment}"
  role   = aws_iam_role.terraform_apply.id
  policy = data.aws_iam_policy_document.apply_policy.json
}
