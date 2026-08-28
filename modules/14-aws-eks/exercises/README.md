# Module 14 Exercises — AWS EKS

Part A uses `../project` (cluster). Part B uses `../project-cicd` (GitHub
Actions). Exercises A1–A4 and B1–B4 do not need an apply.

## Part A — cluster fundamentals (`../project`)

### A1: Control plane vs data plane

From the module README and `eks.tf` / `node_group.tf`:

- What resource is the control plane?
- What is missing when `enable_node_group = false`?
- Could a Deployment become Ready?

### A2: Subnet tags

Open `vpc.tf`. For public and private subnets, list the Kubernetes tags and
what they are for.

### A3: IRSA vs node role

1. Which file creates the OIDC provider?
2. Which service account is the example role scoped to?
3. Why is putting S3 permissions on the node instance role a mistake?

### A4: Compare to the CI/CD skeleton

Read `project-cicd/infra/terraform/modules/vpc/main.tf` and
`project-cicd/infra/terraform/modules/eks/main.tf`.

List four resources `project/` adds that the CI/CD skeleton still lacks.

### A5 (optional, sandbox): Plan only

`terraform init -backend=false` and `terraform plan` in `../project`.
Do **not** apply unless you accept control-plane cost and will destroy today.

## Part B — GitHub Actions delivery (`../project-cicd`)

### B1: Trace a Flask change

A pull request only changes `services/flask-api/app.py`.

- Which `ci.yml` jobs run?
- Which jobs are skipped?
- Which deploy workflow would run if the same change landed on `develop`?

### B2: Map Git refs to environments

| Git ref | GitHub Environment | Typical action |
| --- | --- | --- |
| PR into `main` | | |
| Push to `develop` | | |
| Push to `release/1.4` | | |
| Tag `v1.2.3` | | |
| Push to `main` changing `infra/terraform/environments/iaas/**` | | |

### B3: Terraform state boundaries

Compare `environments/dev` and `environments/prod` under `project-cicd`.

- Backend key for each.
- CIDR for each.
- Why these must not share one state file.
- What `REPLACE_ME-tfstate` is telling you.

### B4: Who owns what?

What should Terraform own on EKS vs what should the deploy workflow own?

## Interview drill

1. IRSA vs ECS task role — same idea or different?
2. Why bind GitHub OIDC trust to an environment name?
3. When would you choose ECS (Module 13) instead of EKS?
