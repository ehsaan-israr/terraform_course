# Module 13 - AWS Glue Jobs with Terraform

This module applies production Terraform habits to **AWS Glue**: config-driven
jobs, one state file per environment, scripts stored in S3, and GitOps CI that
plans every account on a pull request.

You do not need to become a Spark expert. You need to manage Glue jobs the way
a platform team would: many jobs, four stages, no copy-pasted Terraform per job,
and no long-lived AWS keys in GitHub.

## Learning objectives

By the end of this module you will be able to:

- Explain what an AWS Glue ETL job is and which pieces Terraform should own.
- Model many Glue jobs with one `aws_glue_job` resource and `for_each`.
- Keep per-job runtime config in YAML and generate Terraform variables in CI.
- Skip a job in a stage without maintaining a second stack.
- Upload Python scripts to S3 outside Terraform, then point Glue at the object.
- Wire GitHub Environments + OIDC so each stage assumes a different AWS role.
- Use path filters and `-target` so a one-job change does not plan the world.
- Name cost, IAM, and state pitfalls before they hit production.

## Why Glue belongs in a Terraform course

Glue is a managed Spark service. Teams usually start by clicking a job in the
console, then discover they have twenty jobs, four environments, and no review
trail.

Terraform is a good fit for:

- Job definitions (`aws_glue_job`): workers, Glue version, timeout, IAM role.
- Consistent naming and tags across stages.
- Destroying a job when it is skipped or deleted from config.

Terraform is a poor fit for:

- The PySpark script body (keep it as files; upload to S3 in CI).
- Per-environment IAM roles and script buckets if another stack already owns
  them. Pass those in as variables.

The project in this module is a complete Glue domain you can copy into its own
repository.

## Glue mental model

```text
GitHub Actions (OIDC)
        |
        v
+------------------+     +-------------------------+
| Generate tfvars  | --> | Terraform aws_glue_job  |
| from job.yaml    |     | for_each = var.glue_jobs|
+------------------+     +------------+------------+
                                      |
                                      v
                         +-------------------------+
                         | Glue job                |
                         | role = GLUE_ROLE_ARN    |
                         | script = s3://bucket/...|
                         +-------------------------+
                                      |
                                      v
                         +-------------------------+
                         | Spark ETL in AWS        |
                         | reads source, writes    |
                         | curated data            |
                         +-------------------------+
```

Important objects:

| Piece | Who owns it in this lab |
| --- | --- |
| Job definition | Terraform (`gluejobs/terraform`) |
| Per-job config | `gluejobs/<job>/job.yaml` |
| Spark script | `gluejobs/<job>/scripts/main.py` uploaded to S3 in CI |
| Execution role | Existing IAM role ARN (`GLUE_ROLE_ARN`) |
| Script bucket | Existing S3 bucket (`SCRIPTS_S3_BUCKET`) |
| CI credentials | GitHub Environment secret `AWS_ROLE_ARN` via OIDC |

## One stack, many jobs

Do **not** put a Terraform root inside every job folder. That multiplies state
files, backends, and CI matrices.

This lab uses one resource:

```hcl
resource "aws_glue_job" "this" {
  for_each = var.glue_jobs

  name              = "${var.environment}-${each.value.name}"
  role_arn          = var.glue_role_arn
  glue_version      = lookup(each.value, "glue_version", "4.0")
  worker_type       = lookup(each.value, "worker_type", "G.1X")
  number_of_workers = lookup(each.value, "number_of_workers", 2)

  command {
    name            = "glueetl"
    script_location = "s3://${var.scripts_s3_bucket}/${var.scripts_s3_prefix}/${each.value.job_folder}/..."
    python_version  = "3"
  }
}
```

`var.glue_jobs` is generated from YAML. Adding a job means adding a folder, not
editing HCL.

A wrapper module (`modules/glue-job/`) is only worth it if several Terraform
roots reuse the same interface. Here there is one root, so inline `for_each`
is clearer.

## YAML merge rules

Each `job.yaml` is the source of truth. CI merges:

1. Job-level fields (Glue version, workers, timeout).
2. `default_arguments` for every stage.
3. `stages.<env>` overrides.
4. Stage `arguments` on top of `default_arguments`.

Skip a stage with `skip_stages: [qa]` or `stages.qa.skip: true`. The generator
omits that job from that stage's tfvars. If the job already existed, the next
apply **destroys** it in that account. That is intended.

Sample jobs in the project:

| Job | Pattern |
| --- | --- |
| `customer-etl` | Shared defaults + per-stage buckets; prod uses Glue 5.0 |
| `orders-etl` | Same arguments everywhere; skipped in QA |
| `inventory-sync` | Stage-only arguments; skipped in QA |

Bucket names and endpoints use generic `acme-*` placeholders. Replace them in a
sandbox; never commit real account IDs, company hostnames, or credentials.

## CI/CD shape

| Workflow | When | Action |
| --- | --- | --- |
| `glue-plan.yml` | PR or manual | Plan **all** GitHub environments in a matrix |
| `glue-deploy.yml` | Push to `main`/`qa`/`uat`/`prod` | Apply the mapped environment |
| `reusable-glue-terraform.yml` | Called by both | Generate tfvars, optional S3 sync, plan/apply |

Branch mapping: `main` → `dev`, then `qa` → `uat` → `prod`.

GitHub Environments hold per-stage `AWS_ROLE_ARN`, `GLUE_ROLE_ARN`,
`SCRIPTS_S3_BUCKET`, and `vars.env`. That is how one workflow hits four AWS
accounts without hardcoding account IDs.

Selective mode: if only `gluejobs/customer-etl/**` changed, CI still generates
**all** jobs in tfvars (so Terraform does not destroy the others) but passes
`-target` for the changed job. Shared Terraform or script changes force a full
plan.

## Local loop (no apply required)

From `modules/13-aws-glue/project`:

```bash
pip install -r gluejobs/scripts/requirements.txt
python gluejobs/scripts/generate-tfvars.py --stage dev
cat gluejobs/terraform/generated/glue-jobs.auto.tfvars.json

cd gluejobs/terraform
cp terraform.tfvars.example terraform.tfvars
# edit placeholders; never commit terraform.tfvars
terraform init -backend=false
terraform validate
terraform fmt
```

`terraform plan` needs an AWS identity, a real Glue role ARN, and a script
bucket. Use a sandbox. Glue DPUs are not free.

To use the GitHub Actions as written, copy this `project/` directory into its
own repository so `gluejobs/` is at the repo root.

## Production practices

- **OIDC, not access keys.** `AWS_ROLE_ARN` is assumed with `id-token: write`.
- **Scripts are artifacts.** CI uploads them; Terraform only stores the S3 URI.
- **State per environment.** Backend key `glue-jobs/<env>/terraform.tfstate`.
- **Path filters** keep Glue pipelines from firing on unrelated monorepo paths.
- **Least privilege Glue role.** The job role needs S3 and Glue permissions for
  its data paths, not `AdministratorAccess`.
- **Bookmarks and retries** belong in `job.yaml`, not tribal knowledge.

## Common mistakes

1. One Terraform root per job — unmanageable state and CI.
2. Filtering tfvars to changed jobs — Terraform will destroy the omitted jobs.
3. Committing `terraform.tfvars` with real account IDs or role ARNs.
4. Storing Spark scripts only in Terraform `heredoc` — unreviewable and huge.
5. Applying Glue from a laptop to production.
6. Leaving jobs running after class. Destroy them.

## Interview Q&A

**Why `for_each` instead of `count` for Glue jobs?**
Jobs have stable names. `for_each` uses those names as keys, so adding or
removing one job does not shuffle the others.

**Why generate tfvars instead of writing HCL for each job?**
Data engineers own job YAML. Platform engineers own the Terraform contract.
CI is the boundary.

**What happens if you omit an existing job from tfvars?**
Terraform plans a destroy for that job in that state. Use skip flags only when
you mean it.

**Where should the Glue IAM role live?**
Usually in a shared IAM or account-bootstrap stack. This Glue stack consumes
the ARN. Duplicating IAM in every job root creates drift.

**How do you keep CI from destroying unchanged jobs when targeting one job?**
Generate the full map. Limit `-target` and S3 uploads only.

## Mini project

Complete the exercises, then add a fourth job `returns-etl` that:

- Deploys to `dev`, `uat`, and `prod` but skips `qa`.
- Uses Glue 4.0 in non-prod and Glue 5.0 in prod.
- Reads `--source-bucket` / `--target-bucket` arguments.

You should not need to edit `main.tf`.

## Further reading

- AWS Glue jobs: https://docs.aws.amazon.com/glue/latest/dg/author-job.html
- Terraform `aws_glue_job`: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_job
- GitHub OIDC with AWS: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
