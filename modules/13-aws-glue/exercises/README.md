# Module 13 Exercises — AWS Glue Jobs

Use the project in `../project`. You can complete exercises 1–3 without AWS.
Exercises 4–5 need a sandbox account if you want a real plan.

## Exercise 1: Trace a job into Terraform

For `customer-etl` in the `prod` stage, write down:

- Final Glue version, worker type, and worker count.
- Merged default arguments (keys only).
- Whether the job is skipped.

Hint: read `gluejobs/customer-etl/job.yaml`, then run:

```bash
python gluejobs/scripts/generate-tfvars.py --stage prod
```

Deliverable: the resolved prod object for `customer-etl`.

## Exercise 2: Explain skip behavior

`orders-etl` uses `skip_stages`. `inventory-sync` uses `stages.qa.skip`.

Deliverable:

- Which jobs appear in generated tfvars for `qa`?
- If `orders-etl` already existed in the QA AWS account, what does the next
  apply do?
- Why must generated tfvars still include jobs that did **not** change?

## Exercise 3: Add a job without touching HCL

Add `returns-etl` with:

- `skip_stages: [qa]`
- Glue 4.0 by default, Glue 5.0 in prod
- `--source-bucket` and `--target-bucket` per stage using `acme-*` placeholders

Do not edit `gluejobs/terraform/main.tf`.

Deliverable: `job.yaml`, a stub `scripts/main.py`, and generate-tfvars output
for `dev` and `qa`.

## Exercise 4: Design the IAM boundary

Draw or list:

- What the **GitHub OIDC deploy role** may do (Terraform + S3 upload).
- What the **Glue job execution role** may do (read source, write target).
- Why those should be different roles.

Deliverable: a short IAM design (bullet list is enough). No real account IDs.

## Exercise 5: CI change detection

From the project README, answer:

1. A PR only changes `gluejobs/customer-etl/scripts/main.py`. What does CI plan?
2. A PR changes `gluejobs/terraform/main.tf`. What does CI plan?
3. Why is filtering tfvars to the changed job dangerous?

## Interview drill

Answer in two minutes each:

1. What should Terraform own for Glue, and what should stay in Git/S3?
2. How do four GitHub Environments map onto four AWS accounts without
   hardcoding account IDs in the workflow YAML?
3. When is a separate `modules/glue-job/` Terraform module justified?
