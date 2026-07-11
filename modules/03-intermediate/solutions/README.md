# Module 3 Solutions - Intermediate Terraform

These answers correspond to `../exercises/README.md` and use the project in
`../project`.

## Exercise 1: Convert from `count` to `for_each`

A temporary `count` example for two web instances would look like this:

```hcl
resource "aws_instance" "web" {
  count = 2

  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = local.default_subnet_ids[count.index % length(local.default_subnet_ids)]
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true

  tags = {
    Name = "${local.name_prefix}-web-${count.index}"
    Role = "web"
  }
}
```

The addresses are:

```text
aws_instance.web[0]
aws_instance.web[1]
```

The equivalent `for_each` version uses stable names as keys:

```hcl
locals {
  web_servers = {
    web-a = {
      instance_type = "t3.micro"
      subnet_id      = local.default_subnet_ids[0]
    }
    web-b = {
      instance_type = "t3.micro"
      subnet_id      = local.default_subnet_ids[1 % length(local.default_subnet_ids)]
    }
  }
}

resource "aws_instance" "web" {
  for_each = local.web_servers

  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true

  tags = {
    Name = "${local.name_prefix}-${each.key}"
    Role = "web"
  }
}
```

The new addresses are:

```text
aws_instance.web["web-a"]
aws_instance.web["web-b"]
```

Terraform tracks identity by address, not by similar-looking arguments. Without
a state move, Terraform sees `aws_instance.web[0]` removed and
`aws_instance.web["web-a"]` added. That can produce a destroy/create plan even
when both blocks describe the same intended EC2 instance.

Use `moved` blocks during a reviewed refactor:

```hcl
moved {
  from = aws_instance.web[0]
  to   = aws_instance.web["web-a"]
}

moved {
  from = aws_instance.web[1]
  to   = aws_instance.web["web-b"]
}
```

In older Terraform versions or one-off operations, use `terraform state mv`
instead:

```bash
terraform state mv 'aws_instance.web[0]' 'aws_instance.web["web-a"]'
terraform state mv 'aws_instance.web[1]' 'aws_instance.web["web-b"]'
```

The Module 3 project already uses this safer pattern for the main server fleet:

```hcl
resource "aws_instance" "server" {
  for_each = var.servers

  instance_type = each.value.instance_type
  subnet_id     = local.server_subnet_ids[each.key]

  tags = {
    Name = "${local.name_prefix}-${each.key}"
    Role = each.value.role
  }
}
```

## Exercise 2: Add HTTPS with a dynamic ingress rule

Because `aws_security_group.app` is driven by `var.ingress_rules`, add an
`https` key to the variable default or to a `.tfvars` file. No change is needed
in `main.tf`.

Example `terraform.tfvars`:

```hcl
admin_password = "use-a-lab-only-value"

ingress_rules = {
  http = {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  https = {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ssh = {
    description = "SSH from trusted documentation CIDR; replace before apply"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.10/32"]
  }
}
```

Or add it to the default map in `variables.tf`:

```diff
   default = {
     http = {
       description = "HTTP from anywhere"
       from_port   = 80
       to_port     = 80
       protocol    = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
     }
+    https = {
+      description = "HTTPS from anywhere"
+      from_port   = 443
+      to_port     = 443
+      protocol    = "tcp"
+      cidr_blocks = ["0.0.0.0/0"]
+    }
     ssh = {
       description = "SSH from trusted documentation CIDR; replace before apply"
       from_port   = 22
```

The generated nested block in the plan should look similar to:

```text
+ ingress {
    + cidr_blocks = [
        + "0.0.0.0/0",
      ]
    + description = "HTTPS from anywhere"
    + from_port   = 443
    + protocol    = "tcp"
    + to_port     = 443
  }
```

The key `https` does not appear directly in the nested `ingress` block, but it
does give the rule a meaningful identity in the input map and in code review.

## Exercise 3: Test lifecycle protection and sensitive output

Uncomment the lifecycle block in `aws_instance.server`:

```hcl
resource "aws_instance" "server" {
  for_each = var.servers

  # ...

  lifecycle {
    prevent_destroy = true
  }
}
```

Then run:

```bash
terraform plan -destroy
```

Expected result: planning fails because every `aws_instance.server[...]` would
need to be destroyed and `prevent_destroy` blocks that action. This is a plan
time protection, which is why it is useful for catching dangerous proposals
before they reach AWS.

Re-comment the block before lab cleanup:

```hcl
# lifecycle {
#   prevent_destroy = true
# }
```

Sensitive output behavior:

```bash
terraform output
```

Normal output hides the value:

```text
admin_password = <sensitive>
```

Intentional raw access still reveals it:

```bash
terraform output -raw admin_password
```

The important lesson is that `sensitive = true` is a display control, not a
secret-storage system. The value can still exist in state. In production, store
long-lived secrets in AWS Secrets Manager, SSM Parameter Store, or a controlled
CI/CD secret store, and protect Terraform state as sensitive data.
