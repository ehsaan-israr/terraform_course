# Terraform and AWS Resources

Use these resources as references while building the course projects. Prefer official documentation for exact arguments and provider behavior; use guides and examples for patterns.

## Terraform and OpenTofu official documentation

- Terraform language documentation: https://developer.hashicorp.com/terraform/language
- Terraform CLI documentation: https://developer.hashicorp.com/terraform/cli
- Terraform style guide: https://developer.hashicorp.com/terraform/language/style
- Terraform modules: https://developer.hashicorp.com/terraform/language/modules
- Terraform backends: https://developer.hashicorp.com/terraform/language/settings/backends/configuration
- Terraform S3 backend: https://developer.hashicorp.com/terraform/language/settings/backends/s3
- Terraform state commands: https://developer.hashicorp.com/terraform/cli/commands/state
- Terraform import: https://developer.hashicorp.com/terraform/language/import
- Terraform moved blocks: https://developer.hashicorp.com/terraform/language/modules/develop/refactoring
- Terraform test framework: https://developer.hashicorp.com/terraform/language/tests
- Terraform Plugin Framework: https://developer.hashicorp.com/terraform/plugin/framework
- Terraform AWS provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- OpenTofu documentation: https://opentofu.org/docs/
- OpenTofu migration guide: https://opentofu.org/docs/intro/migration/
- OpenTofu registry: https://search.opentofu.org/

## AWS architecture and service documentation

- AWS Well-Architected Framework: https://aws.amazon.com/architecture/well-architected/
- AWS Architecture Center: https://aws.amazon.com/architecture/
- AWS Builders' Library: https://aws.amazon.com/builders-library/
- AWS Prescriptive Guidance for Terraform: https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/
- AWS Organizations: https://docs.aws.amazon.com/organizations/
- AWS Control Tower: https://docs.aws.amazon.com/controltower/
- AWS IAM: https://docs.aws.amazon.com/iam/
- AWS STS and role assumption: https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html
- AWS VPC: https://docs.aws.amazon.com/vpc/
- AWS Transit Gateway: https://docs.aws.amazon.com/vpc/latest/tgw/
- AWS PrivateLink and VPC endpoints: https://docs.aws.amazon.com/vpc/latest/privatelink/
- AWS Route53: https://docs.aws.amazon.com/route53/
- AWS Glue: https://docs.aws.amazon.com/glue/latest/dg/what-is-glue.html
- AWS Glue jobs: https://docs.aws.amazon.com/glue/latest/dg/author-job.html
- Terraform `aws_glue_job`: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_job
- GitHub OIDC with AWS: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
- AWS ECS: https://docs.aws.amazon.com/ecs/
- AWS ECR: https://docs.aws.amazon.com/ecr/
- AWS RDS: https://docs.aws.amazon.com/rds/
- Amazon ElastiCache: https://docs.aws.amazon.com/elasticache/
- AWS CloudFront: https://docs.aws.amazon.com/cloudfront/
- AWS WAF: https://docs.aws.amazon.com/waf/
- AWS CloudWatch: https://docs.aws.amazon.com/cloudwatch/
- AWS CloudTrail: https://docs.aws.amazon.com/cloudtrail/
- AWS Backup: https://docs.aws.amazon.com/aws-backup/
- AWS Security Hub: https://docs.aws.amazon.com/securityhub/
- Amazon GuardDuty: https://docs.aws.amazon.com/guardduty/
- IAM Access Analyzer: https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html

## Ecosystem tools

- Terragrunt documentation: https://terragrunt.gruntwork.io/
- Terragrunt reference architecture examples: https://github.com/gruntwork-io/terragrunt-infrastructure-live-example
- Atlantis documentation: https://www.runatlantis.io/docs/
- Atlantis repository: https://github.com/runatlantis/atlantis
- Terraform Cloud docs: https://developer.hashicorp.com/terraform/cloud-docs
- Terraform Cloud dynamic provider credentials: https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials
- Terraform Cloud private registry: https://developer.hashicorp.com/terraform/cloud-docs/registry
- Terraform Cloud run tasks: https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings/run-tasks
- Sentinel documentation: https://developer.hashicorp.com/sentinel/docs
- Spacelift documentation: https://docs.spacelift.io/
- Spacelift policies: https://docs.spacelift.io/concepts/policy
- Infracost documentation: https://www.infracost.io/docs/
- Infracost usage-based resources: https://www.infracost.io/docs/features/usage_based_resources/
- Open Policy Agent: https://www.openpolicyagent.org/docs/latest/

## Security, scanning, and policy tools

- TFLint: https://github.com/terraform-linters/tflint
- TFLint AWS ruleset: https://github.com/terraform-linters/tflint-ruleset-aws
- Checkov: https://www.checkov.io/
- tfsec: https://aquasecurity.github.io/tfsec/
- Trivy misconfiguration scanning: https://aquasecurity.github.io/trivy/latest/docs/scanner/misconfiguration/
- Terrascan: https://runterrascan.io/
- Conftest: https://www.conftest.dev/
- OPA/Rego policy language: https://www.openpolicyagent.org/docs/latest/policy-language/
- AWS IAM policy evaluation logic: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html
- AWS security best practices in IAM: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- AWS Well-Architected Security Pillar: https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html

## Cost and FinOps

- AWS Pricing Calculator: https://calculator.aws/
- AWS Cost Explorer: https://docs.aws.amazon.com/cost-management/latest/userguide/ce-what-is.html
- AWS Budgets: https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html
- AWS Cost Categories: https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/manage-cost-categories.html
- Infracost CI/CD integrations: https://www.infracost.io/docs/integrations/cicd/
- FinOps Foundation: https://www.finops.org/

## Example modules and repositories

- Terraform AWS modules organization: https://github.com/terraform-aws-modules
- AWS samples organization: https://github.com/aws-samples
- HashiCorp Terraform guides and examples: https://github.com/hashicorp/terraform-guides
- HashiCorp Learn Terraform examples: https://github.com/hashicorp/learn-terraform-provision-eks-cluster
- Gruntwork infrastructure live example: https://github.com/gruntwork-io/terragrunt-infrastructure-live-example
- Gruntwork infrastructure modules example: https://github.com/gruntwork-io/terragrunt-infrastructure-modules-example
- AWS Control Tower Account Factory for Terraform: https://docs.aws.amazon.com/controltower/latest/userguide/aft-overview.html

## Books and long-form learning

- *Terraform: Up and Running* by Yevgeniy Brikman
- *Infrastructure as Code* by Kief Morris
- *AWS Security Best Practices* whitepapers: https://aws.amazon.com/whitepapers/
- AWS Builder Labs and workshops: https://workshops.aws/
- Gruntwork guides: https://www.gruntwork.io/guides
- HashiCorp Developer tutorials: https://developer.hashicorp.com/terraform/tutorials
- OpenTofu learning resources: https://opentofu.org/docs/intro/

## Production readiness checklists

- Remote state and locking are enabled.
- State bucket has versioning, encryption, and restricted access.
- Provider versions are pinned and lock files are committed.
- Plans are generated by trusted automation for shared environments.
- Production applies require approval.
- IAM roles use short-lived credentials where possible.
- Modules include tags, encryption, logging, and backup defaults.
- Destructive plans require explicit migration notes.
- Monitoring and runbooks ship with services.
- DR restore tests are scheduled, not assumed.

## Practice advice

- Read provider docs before writing resources.
- Keep plans small and reviewable.
- Prefer explicit module contracts over clever implicit behavior.
- Write migration notes for imports, moves, and refactors.
- Add validation to variables where invalid input would create unsafe infrastructure.
- Test with lower environments before production.
- Make ownership visible through tags, CODEOWNERS, and module docs.
- Treat cost as a design constraint, not an afterthought.
- Test disaster recovery before production needs it.
