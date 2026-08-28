# Module 14 Solutions — EKS CI/CD

These answers correspond to `../exercises/README.md`.

## Exercise 1: Trace a Flask change

`ci.yml` path filter sets `flask-api: true` and the other service/terraform
flags false.

Runs: `changes`, then `flask-api` (reusable Python lint + pytest).

Skipped: `fastapi-api`, `go-api`, and all `terraform-plan-*` jobs.

On `develop`, `deploy-dev.yml` would build/push/deploy. With a Flask-only
change, a well-written release workflow should still **prefer** deploying only
changed services; read `reusable-release.yml` / `deploy-dev.yml` toggles. The
default teaching pipelines deploy the catalog unless inputs disable a service.

## Exercise 2: Map Git refs to environments

| Git ref | GitHub Environment | Typical action |
| --- | --- | --- |
| PR into `main` | (none for apps); Terraform jobs use `dev`/`qa`/`prod`/`iaas` | Lint/test + Terraform **plan** |
| Push to `develop` | `dev` | Build, ECR push, EKS deploy |
| Push to `release/1.4` | `qa` | Build, ECR push, EKS deploy |
| Tag `v1.2.3` | `prod` | Build, ECR push, EKS deploy with approval |
| Push to `main` changing iaas Terraform | `iaas` | Terraform **apply** via `terraform-iaas.yml` |

## Exercise 3: Terraform state boundaries

| Root | Backend key | Sample CIDR |
| --- | --- | --- |
| dev | `dev/terraform.tfstate` | `10.0.0.0/16` |
| prod | `prod/terraform.tfstate` | `10.2.0.0/16` |

One state file would couple prod cluster replacement to a dev experiment.
Locking, IAM, and approvals would also mix.

`REPLACE_ME-tfstate` is a placeholder. Real bucket names stay in sandbox
overrides or a private fork — not in the public course.

## Exercise 4: EKS skeleton gap analysis

Examples Terraform should own:

1. Internet gateway + public routes.
2. NAT gateway (or VPC endpoints) so private nodes can pull images.
3. EKS managed node group or Fargate profile.
4. Cluster security groups / API endpoint access.
5. `aws-auth` / access entries, IRSA, and add-ons (VPC CNI, CoreDNS).

Deploy workflow should own: image build, pushing to ECR, and rolling the
Deployment to a new tag (`kubectl set image` in this lab).

## Interview drill

1. OIDC issues short-lived credentials bound to a repo and environment. Stolen
   static keys work until someone rotates them.
2. `prod` is one app cluster. `iaas` is shared foundation; a bad apply can
   break every environment that depends on it. Higher approval bar.
3. Without path filters, every PR pays for all language toolchains, image
   builds, and four Terraform plans. That is slow and increases the chance of
   unrelated apply mistakes.
