# Module 13 Solutions — AWS Glue Jobs

These answers correspond to `../exercises/README.md` and use `../project`.

## Exercise 1: Trace a job into Terraform

From `gluejobs/customer-etl/job.yaml` for `prod`:

| Field | Value |
| --- | --- |
| Glue version | `5.0` (stage override; job default is `4.0`) |
| Worker type | `G.2X` |
| Workers | `10` |
| Skipped | no |

Merged argument keys:

- `--enable-metrics`
- `--job-bookmark-option`
- `--database`
- `--env`
- `--source-bucket`
- `--target-bucket`

`generate-tfvars.py --stage prod` should emit a `customer-etl` object with
`job_folder` of `customer-etl` and those arguments. Terraform names the AWS
job `prod-customer-etl`.

## Exercise 2: Explain skip behavior

QA generated jobs: **`customer-etl` only**.

- `orders-etl` is listed in `skip_stages: [qa]`.
- `inventory-sync` has `stages.qa.skip: true`.

If `orders-etl` already existed in QA, the next apply **destroys** it there
because it is absent from `var.glue_jobs` for that state file.

Generated tfvars must include every active job for the stage. If CI wrote only
the changed job, Terraform would treat the others as removed and destroy them.
Selective CI limits `-target` and S3 uploads, not the tfvars map.

## Exercise 3: Add a job without touching HCL

Example `gluejobs/returns-etl/job.yaml`:

```yaml
name: returns-etl
description: Returns fact ETL
glue_version: "4.0"
worker_type: G.1X
number_of_workers: 2
script: scripts/main.py

skip_stages:
  - qa

default_arguments:
  --enable-metrics: ""

stages:
  dev:
    arguments:
      --env: dev
      --source-bucket: acme-data-dev
      --target-bucket: acme-curated-dev
  uat:
    arguments:
      --env: uat
      --source-bucket: acme-data-uat
      --target-bucket: acme-curated-uat
  prod:
    glue_version: "5.0"
    arguments:
      --env: prod
      --source-bucket: acme-data-prod
      --target-bucket: acme-curated-prod
```

`generate-tfvars.py --stage dev` includes `returns-etl`.
`generate-tfvars.py --stage qa` omits it. `main.tf` is unchanged because
`for_each = var.glue_jobs`.

## Exercise 4: Design the IAM boundary

**GitHub OIDC deploy role** (used by Actions):

- `glue:CreateJob`, `UpdateJob`, `DeleteJob`, `GetJob`, tags
- `iam:PassRole` only for the Glue execution role
- `s3:PutObject` / `DeleteObject` on the **scripts** prefix
- `dynamodb` / `s3` for Terraform state if the backend lives in that account

**Glue job execution role** (used at runtime):

- Read `s3://acme-data-<env>/...`
- Write `s3://acme-curated-<env>/...`
- Read the script object
- Glue catalog / CloudWatch logs as needed

They are different identities: CI should not be able to read production data,
and Spark jobs should not be able to change Terraform state or IAM.

## Exercise 5: CI change detection

1. Selective plan/apply for **customer-etl** only (`-target`), full tfvars.
2. **Full** plan/apply for all active jobs (shared Terraform path).
3. Filtering tfvars would drop unchanged jobs from state desired config and
   destroy them.

## Interview drill

1. Terraform owns job resources, names, workers, Glue version, role ARN, and
   the S3 URI of the script. Git owns YAML and PySpark. CI uploads scripts.
2. Each matrix job sets `environment: dev|qa|uat|prod`. GitHub injects that
   environment's `AWS_ROLE_ARN` and variables. The workflow YAML stays generic.
3. A dedicated module is justified when **multiple Terraform roots** need the
   same Glue job interface. One root with `for_each` does not need the extra
   layer.
