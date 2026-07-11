# Module 1 Solutions - IaC Fundamentals

These answers correspond to `../exercises/README.md`. Run them only in a
sandbox AWS account and destroy resources when you are done.

## Exercise 1: Read a plan like a change ticket

The Module 1 project creates these managed resources:

- `aws_s3_bucket.app`
- `aws_s3_bucket_public_access_block.app`
- `aws_s3_bucket_server_side_encryption_configuration.app`
- `aws_s3_bucket_versioning.app`
- `aws_security_group.web`
- `aws_instance.web`

It also reads data sources:

- `data.aws_vpc.default`
- `data.aws_subnets.default`
- `data.aws_ami.amazon_linux_2023`

Data sources are read during planning. Resources are created during apply.

Example plan fragments you should be able to explain:

```text
# aws_s3_bucket.app will be created
+ resource "aws_s3_bucket" "app" {
    + arn    = (known after apply)
    + bucket = "my-unique-module-1-bucket"
    + id     = (known after apply)
    + tags   = {
        + "Name" = "iac-fundamentals-dev-app"
      }
  }
```

What is known before apply:

- `bucket`, because it comes from `var.bucket_name`.
- `tags.Name`, because it is built from declared variables.

What is known after apply:

- `arn`, `id`, regional domain names, and other provider-computed attributes.
- Terraform cannot know these until the AWS API accepts the bucket creation and
  returns the final remote object metadata.

Another useful fragment:

```text
# aws_instance.web will be created
+ resource "aws_instance" "web" {
    + ami                         = "ami-..."
    + instance_type               = "t3.micro"
    + public_dns                  = (known after apply)
    + public_ip                   = (known after apply)
    + subnet_id                   = "subnet-..."
    + vpc_security_group_ids      = (known after apply)
  }
```

The AMI and subnet can usually be known during plan because they come from data
sources. The public IP, public DNS name, instance ID, and final network
interface details are assigned by AWS only after the instance is launched.

### Explained sample diff

If your starting configuration is the project as written, a minimal S3 bucket
change ticket looks like this:

```diff
 resource "aws_s3_bucket" "app" {
   bucket = var.bucket_name

   tags = {
     Name = "${var.project_name}-${var.environment}-app"
   }
 }
```

There is no code change required for the exercise. The learning goal is to map
plan symbols to intent:

- `+` means create.
- `~` means update in place.
- `-/+` means replace.
- `(known after apply)` means the provider will compute the value after calling
  AWS.

## Exercise 2: Modify EC2 safely

Change `instance_type` through a variable value rather than editing the resource
body. For example, in `terraform.tfvars`:

```hcl
bucket_name    = "my-unique-module-1-bucket"
ssh_cidr_block = "203.0.113.10/32"
instance_type  = "t3.small"
```

Expected plan shape:

```text
# aws_instance.web will be updated in-place
~ resource "aws_instance" "web" {
    ~ instance_type = "t3.micro" -> "t3.small"
      id            = "i-..."
  }
```

This is an in-place Terraform update because the address stays
`aws_instance.web`. In AWS, changing an EC2 instance type for an existing
instance generally requires stopping and starting the instance. That means a
single-instance demo can experience downtime even when Terraform does not show
replacement.

Production interpretation:

- Behind a load balancer, resize one instance at a time or use a rolling
  deployment pattern.
- For a single instance, schedule a maintenance window.
- If the plan shows `-/+`, Terraform will replace the instance and the impact is
  larger because the old remote object is destroyed and a new one is created.

### Explained sample diff

```diff
 variable "instance_type" {
   description = "EC2 instance type. t3.micro is free-tier eligible in many AWS accounts; use t2.micro if your account/region requires it."
   type        = string
-  default     = "t3.micro"
+  default     = "t3.small"
 }
```

Prefer a `terraform.tfvars` override for a lab so the default remains
low-cost. The diff above is useful for understanding the plan, but it would make
the course default more expensive.

## Exercise 3: Observe drift

After applying the project, manually change the EC2 `Name` tag in the AWS
Console. The Terraform configuration still says:

```hcl
resource "aws_instance" "web" {
  # ...

  tags = {
    Name = "${var.project_name}-${var.environment}-web"
  }
}
```

After refresh, the plan should propose reverting the tag:

```text
# aws_instance.web will be updated in-place
~ resource "aws_instance" "web" {
    ~ tags = {
        ~ "Name" = "manual-console-name" -> "iac-fundamentals-dev-web"
      }
  }
```

You have two valid choices:

1. Keep Terraform as the source of truth and run `terraform apply` to revert the
   manual console change.
2. Accept the manual value by changing Terraform code, then apply that reviewed
   change.

For example, to encode a new naming pattern:

```diff
 resource "aws_instance" "web" {
   # ...

   tags = {
-    Name = "${var.project_name}-${var.environment}-web"
+    Name = "${var.project_name}-${var.environment}-frontend"
   }
 }
```

That diff makes the desired value explicit. Do not repeatedly patch resources in
the console and ignore the resulting drift; that leaves future reviewers unable
to tell which system owns the final value.

## Cleanup

When finished:

```bash
terraform destroy
```

Review the destroy plan before confirming, especially the S3 bucket and EC2
instance resources.
