# Module 1 LocalStack Project - EC2 + S3 without a real AWS account

This folder is the LocalStack twin of `../project`. It uses the real
`hashicorp/aws` provider pointed at LocalStack in Docker so you can practice
`init` / `plan` / `apply` / `destroy` without AWS credentials.

For the real-AWS lab (default VPC, Amazon Linux AMI lookup, live Apache page),
use `../project` instead.

## What it creates

- A small VPC and subnet (LocalStack has no reliable default VPC for this lab)
- An S3 bucket with public access blocked, versioning, and AES-256 encryption
- A security group allowing HTTP and SSH from a CIDR
- An EC2 instance record (API mock only — no real guest OS or Apache)

## Prerequisites

- Terraform 1.6 or newer
- Docker and Docker Compose

No AWS account or credentials are required.

## Files

```text
versions.tf                 Terraform and provider version constraints
providers.tf                AWS provider pointed at LocalStack
variables.tf                Input variables
main.tf                     VPC, subnet, S3, security group, EC2
outputs.tf                  Values printed after apply
docker-compose.yml          LocalStack container
localstack-init/ready.d/    Registers placeholder AMI on container start
terraform.tfvars.example    Example variable values
.gitignore                  Ignores local state and private tfvars
```

## Run

### 1. Start LocalStack

```bash
docker compose up -d
docker compose ps
docker compose logs localstack | grep -E 'Registered LocalStack AMI|Ready'
```

Wait until the container is healthy and the init script has registered
`al2023-ami-localstack`.

### 2. Configure variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Optional env vars:

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
```

### 3. Plan and apply

```bash
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Clean up

```bash
terraform destroy
docker compose down
```

Use `docker compose down -v` to also wipe the LocalStack data volume (including
the registered AMI).

## Limits

LocalStack mocks AWS APIs. It does **not** boot a real EC2 VM or run Apache, so
`web_url` will not serve a real page. Use this project for Terraform workflow
practice; use `../project` when you want the live HTTP demo on real AWS.

If `data.aws_ami.localstack` returns no results:

```bash
docker compose down -v
docker compose up -d
docker compose logs localstack | grep Registered
```

## Troubleshooting

- **LocalStack connection refused:** Run `docker compose up -d` and confirm port `4566`.
- **AMI query returned no results:** Restart with `docker compose down -v && docker compose up -d`.
- **web_url does nothing:** Expected on LocalStack.
