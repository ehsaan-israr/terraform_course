# Terraform and AWS Resources

## Official documentation

- Terraform language documentation: https://developer.hashicorp.com/terraform/language
- Terraform CLI documentation: https://developer.hashicorp.com/terraform/cli
- Terraform AWS provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Terraform Plugin Framework: https://developer.hashicorp.com/terraform/plugin/framework
- AWS Well-Architected Framework: https://aws.amazon.com/architecture/well-architected/
- AWS Prescriptive Guidance for Terraform: https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/
- AWS ECS documentation: https://docs.aws.amazon.com/ecs/
- AWS RDS documentation: https://docs.aws.amazon.com/rds/
- AWS CloudFront documentation: https://docs.aws.amazon.com/cloudfront/

## Ecosystem tools

- Terragrunt: https://terragrunt.gruntwork.io/
- Atlantis: https://www.runatlantis.io/
- Terraform Cloud: https://developer.hashicorp.com/terraform/cloud-docs
- Spacelift: https://docs.spacelift.io/
- OpenTofu: https://opentofu.org/docs/
- Infracost: https://www.infracost.io/docs/
- Trivy IaC scanning: https://aquasecurity.github.io/trivy/latest/docs/scanner/misconfiguration/

## Books and learning

- *Terraform: Up and Running* by Yevgeniy Brikman
- *Infrastructure as Code* by Kief Morris
- AWS Builders' Library: https://aws.amazon.com/builders-library/
- Gruntwork guides: https://www.gruntwork.io/guides

## Example repositories

- Terraform AWS modules organization: https://github.com/terraform-aws-modules
- HashiCorp learn examples: https://github.com/hashicorp/learn-terraform-provision-eks-cluster
- AWS samples: https://github.com/aws-samples

## Practice advice

- Read provider docs before writing resources.
- Keep plans small and reviewable.
- Prefer explicit module contracts over clever implicit behavior.
- Write migration notes for imports, moves, and refactors.
- Test disaster recovery before production needs it.
