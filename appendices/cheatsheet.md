# Terraform CLI and HCL Cheatsheet

## Common CLI commands

```bash
terraform fmt -recursive
terraform init
terraform validate
terraform plan
terraform plan -out=tfplan
terraform apply tfplan
terraform destroy
terraform state list
terraform state show aws_vpc.main
terraform providers
terraform workspace list
```

## Remote backend init

```bash
terraform init -backend-config=backend.hcl
```

## Import block

```hcl
import {
  to = aws_s3_bucket.logs
  id = "my-existing-bucket"
}
```

## Moved block

```hcl
moved {
  from = aws_instance.web
  to   = module.compute.aws_instance.this
}
```

## Provider pinning

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## Useful HCL patterns

```hcl
locals {
  tags = merge(var.tags, {
    ManagedBy = "terraform"
  })
}

resource "aws_subnet" "private" {
  for_each = toset(var.availability_zones)

  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(var.availability_zones, each.key))
}

policy = jsonencode({
  Version = "2012-10-17"
  Statement = [{
    Effect   = "Allow"
    Action   = ["s3:GetObject"]
    Resource = ["${aws_s3_bucket.app.arn}/*"]
  }]
})
```

## Plan review checklist

- Are there unexpected destroys or replacements?
- Did provider versions change?
- Did state addresses move intentionally?
- Are sensitive values hidden?
- Are production changes approved by the right owners?
