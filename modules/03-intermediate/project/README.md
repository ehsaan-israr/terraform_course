# Module 3 Project - Multi-server Application

This project demonstrates intermediate Terraform patterns in `us-east-1`:

- Data sources for AWS account, default VPC/subnets, and latest Amazon Linux 2023 AMI.
- `for_each` over a `servers` map.
- Dynamic ingress blocks from an `ingress_rules` map.
- Conditional Elastic IP creation with `create_elastic_ips`.
- Sensitive input and output for a demo admin password.
- Commented `prevent_destroy` lifecycle guard.

## Prerequisites

- Terraform 1.6 or newer.
- AWS credentials configured locally.
- Permissions for EC2, security groups, Elastic IPs if enabled, and default VPC data lookup.
- A default VPC in `us-east-1`.

Check credentials:

```bash
aws sts get-caller-identity
```

## Configure

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region   = "us-east-1"
project_name = "terraform-intermediate"
environment  = "dev"
key_name     = null

create_elastic_ips = false

servers = {
  web-a = {
    instance_type = "t3.micro"
    role          = "web"
  }
  web-b = {
    instance_type = "t3.micro"
    role          = "web"
  }
  worker-a = {
    instance_type = "t3.micro"
    role          = "worker"
  }
}

ingress_rules = {
  http = {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ssh = {
    description = "SSH from my current public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_PUBLIC_IP/32"]
  }
}

admin_password = "use-a-demo-value-only"
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

View outputs:

```bash
terraform output
terraform output web_urls
```

To intentionally read the sensitive demo password:

```bash
terraform output -raw admin_password
```

## Destroy

```bash
terraform destroy
```

If you uncomment the `prevent_destroy` lifecycle block in `main.tf`, Terraform will block destruction of the protected instances. Re-comment or remove the block before destroying this lab.

## Learning points

- `aws_instance.server` uses `for_each`, so addresses look like `aws_instance.server["web-a"]`.
- `aws_eip.server` uses conditional creation: `var.create_elastic_ips ? var.servers : {}`.
- The security group uses a dynamic `ingress` block to render each rule from `var.ingress_rules`.
- `admin_password` is marked sensitive, which hides normal CLI display but does not remove it from state.

## State and Git warning

Do not commit `terraform.tfstate`, real `terraform.tfvars`, or plan files. This project includes a `.gitignore` for local learning.

For production, store state remotely with encryption and locking. Treat state as sensitive data.

## Troubleshooting

- **Invalid CIDR in SSH rule:** Replace the documentation IP `203.0.113.10/32` with your real public IP and `/32`.
- **Elastic IP quota errors:** Leave `create_elastic_ips = false` or release unused EIPs.
- **No default VPC:** Recreate the default VPC or adapt the project to use an existing VPC/subnet data source.
- **Unexpected replacements after renaming a server key:** `for_each` keys are resource identity. Use a `moved` block or `terraform state mv` for intentional renames.
