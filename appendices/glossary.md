# Glossary

**Apply**: Terraform operation that changes remote infrastructure to match the plan.

**Backend**: Storage and locking configuration for Terraform state.

**Data source**: Read-only lookup of information from a provider.

**Drift**: Difference between Terraform state/configuration and real infrastructure.

**Import block**: Terraform 1.5+ configuration block that maps an existing remote object to a Terraform address.

**Module**: A collection of Terraform files treated as a reusable unit.

**Moved block**: Configuration block that tells Terraform an existing state object moved from one address to another.

**Plan**: Preview of actions Terraform will take.

**Provider**: Plugin that lets Terraform manage an API such as AWS.

**Remote state**: State stored outside the local filesystem, typically in S3 or Terraform Cloud.

**Root module**: The Terraform configuration directory where commands are run.

**State**: Terraform's record of managed resources and their attributes.

**Terragrunt**: Wrapper that helps keep live Terraform configuration DRY across environments.

**Workspace**: Terraform state namespace. Useful in some workflows, but many teams prefer separate root modules per environment.
