# Module 1 Project - EC2 + S3 with Terraform

This project provisions a small AWS environment in `us-east-1`:

- An S3 bucket with public access blocked, versioning enabled, and AES-256 server-side encryption.
- A security group allowing HTTP from the internet and SSH from one trusted CIDR block.
- A free-tier friendly EC2 instance running Apache HTTP Server from `user_data`.

The project intentionally uses the default VPC to keep Module 1 focused on Terraform fundamentals instead of networking design.

To practice the same workflow **without an AWS account**, use the LocalStack twin in [`../project_localstack`](../project_localstack).

## Prerequisites

- Terraform 1.6 or newer.
- AWS credentials configured in your shell.
- Permission to manage EC2, security groups, and S3 in `us-east-1`.
- A globally unique S3 bucket name.

Confirm credentials:

```bash
aws sts get-caller-identity
```

## Files

```text
versions.tf                 Terraform and provider version constraints
providers.tf                AWS provider configuration
variables.tf                Input variables
main.tf                     EC2, security group, S3, and supporting data sources
outputs.tf                  Values printed after apply
terraform.tfvars.example    Example variable values
.gitignore                  Ignores local Terraform state and private variable files
```

## Configure

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region     = "us-east-1"
project_name   = "iac-fundamentals"
environment    = "dev"
bucket_name    = "your-unique-bucket-name-here"
instance_type  = "t3.micro"
ssh_cidr_block = "YOUR_PUBLIC_IP/32"
key_name       = null
```

Find your public IP:

```bash
curl https://checkip.amazonaws.com
```

If you want SSH access, set `key_name` to the name of an existing EC2 key pair in `us-east-1`. If you only want to test HTTP, leave it as `null`.

## Apply

```bash
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

After apply, Terraform prints `web_url`. Open it in a browser:

```bash
terraform output web_url
```

It can take one or two minutes for the EC2 `user_data` script to finish installing and starting Apache.

## Destroy

When finished:

```bash
terraform destroy
```

## State and Git warning

Local Terraform runs create state files such as `terraform.tfstate`. State can contain resource metadata and sometimes sensitive values. Do not commit state files or private `*.tfvars` files.

This project includes a `.gitignore` for local learning. In production teams, use a remote backend such as S3 with DynamoDB locking, encryption, restricted IAM access, and bucket versioning.

## Troubleshooting

- **BucketAlreadyExists:** S3 bucket names are globally unique. Choose a different `bucket_name`.
- **InvalidKeyPair.NotFound:** `key_name` must already exist in the selected AWS region. Use `null` if you do not need SSH.
- **No default VPC:** Some AWS accounts remove the default VPC. Create one for the lab or adapt the code to use explicit VPC/subnet resources.
- **The web page does not load immediately:** Wait for `user_data` to finish, then verify security group port 80 and instance status checks.
