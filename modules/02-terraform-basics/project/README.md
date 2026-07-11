# Module 2 Project - Simple Web Server with Elastic IP

This project builds a small VPC-light AWS environment in `us-east-1`:

- Default VPC and subnet lookup.
- Security group allowing HTTP from anywhere and SSH from your trusted CIDR.
- Amazon Linux 2023 EC2 instance.
- nginx installed and started by `user_data`.
- Elastic IP associated with the instance.

## Prerequisites

- Terraform 1.6 or newer.
- AWS credentials configured locally.
- Permissions for EC2, security groups, Elastic IPs, and default VPC data lookup.
- Optional existing EC2 key pair if you want SSH access.

Verify AWS credentials:

```bash
aws sts get-caller-identity
```

## Configure

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region       = "us-east-1"
project_name     = "terraform-basics"
environment      = "dev"
instance_type    = "t3.micro"
allowed_ssh_cidr = "YOUR_PUBLIC_IP/32"
key_name         = null
```

Find your public IP:

```bash
curl https://checkip.amazonaws.com
```

## Apply

```bash
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Open the web server:

```bash
terraform output web_url
```

The Elastic IP may respond before nginx has finished installing. If the first request fails, wait one or two minutes and retry.

## Destroy

```bash
terraform destroy
```

Elastic IPs can incur cost when left allocated. Always destroy this lab when finished.

## Learning points

- `locals.tf` centralizes common names and tags.
- `aws_instance.web` implicitly depends on `aws_security_group.web` because it references the security group ID.
- `aws_eip.web` implicitly depends on `aws_instance.web` because it references the instance ID.
- Outputs make the public IP and URL easy to consume after apply.

## State and Git warning

The `.gitignore` excludes local state files, private variable files, and plan files. Do not commit `terraform.tfstate` or real `terraform.tfvars`.

In production, use a remote backend with locking instead of local state.

## Troubleshooting

- **AddressLimitExceeded:** Your account may have reached the Elastic IP quota. Release unused EIPs or skip this project until quota is available.
- **InvalidKeyPair.NotFound:** Set `key_name = null` or use an existing key pair in `us-east-1`.
- **No default VPC found:** Recreate the default VPC or adapt the project to create its own VPC.
- **SSH timeout:** Confirm `allowed_ssh_cidr` is your current public IP with `/32`, and use the correct private key.
