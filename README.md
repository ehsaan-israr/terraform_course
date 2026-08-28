# Terraform from Zero to Production

A complete, project-based course that takes a backend engineer from **first Terraform commands** to **enterprise AWS platform engineering**.

**Focus:** AWS + Terraform for production engineering  
**Audience:** Backend engineers with AWS, Go/Python, Docker, and Linux experience who have not used Terraform professionally  
**Region used throughout:** `us-east-1`

---

## What you will build

| Stage | Outcome |
| --- | --- |
| Modules 1–3 | EC2, S3, web server, multi-server apps with `count` / `for_each` |
| Modules 4–6 | Remote state, reusable modules, production-shaped AWS platform |
| Modules 7–9 | Multi-env repos, security hardening, Terratest + CI validation |
| Modules 10–12 | Refactoring, GitOps ecosystem, multi-account landing zone |
| Module 13 | Config-driven AWS Glue jobs, YAML → Terraform, OIDC CI |
| Module 14 | Monorepo GitHub Actions, EKS deploys, Terraform per env |
| Capstone | CloudFront → ALB → ECS → RDS/Redis/S3 with CI, scanning, DR docs |

---

## Course map

```text
01 IaC Fundamentals ──► 02 Terraform Basics ──► 03 Intermediate
         │                       │                      │
         └───────────────────────┴──────────────────────┘
                                 ▼
                    04 State Management
                                 ▼
                         05 Modules
                                 ▼
                  06 AWS Infrastructure
                                 ▼
              07 Production ──► 08 Security ──► 09 Testing
                                 ▼
              10 Advanced ──► 11 Ecosystem ──► 12 Enterprise
                                 ▼
                         13 AWS Glue Jobs
                                 ▼
                    14 GitHub Actions + EKS
                                 ▼
                         Final Capstone
```

| # | Module | Project |
| --- | --- | --- |
| [01](modules/01-iac-fundamentals/) | IaC Fundamentals | EC2 + S3 |
| [02](modules/02-terraform-basics/) | Terraform Basics | Web server (SG + EC2 + EIP) |
| [03](modules/03-intermediate/) | Intermediate Terraform | Multi-server app |
| [04](modules/04-state-management/) | State Management | S3 + DynamoDB remote backend |
| [05](modules/05-modules/) | Modules | VPC, ECS, RDS, Security Groups |
| [06](modules/06-aws-infrastructure/) | AWS Infrastructure | Production platform skeleton |
| [07](modules/07-production/) | Production Terraform | Enterprise live/modules repo |
| [08](modules/08-security/) | Security | Harden insecure infrastructure |
| [09](modules/09-testing/) | Testing & Validation | Terratest + validation pipeline |
| [10](modules/10-advanced/) | Advanced Terraform | Monolith → modules migration |
| [11](modules/11-ecosystem/) | Terraform Ecosystem | Terragrunt + GitOps workflow |
| [12](modules/12-enterprise/) | Enterprise Architecture | Multi-account landing zone |
| [13](modules/13-aws-glue/) | AWS Glue Jobs | YAML-driven Glue jobs + OIDC CI |
| [14](modules/14-eks-cicd/) | GitHub Actions + EKS | Monorepo CI/CD, Terraform, EKS rollouts |
| [Capstone](capstone/) | Production Platform | Full CloudFront/ALB/ECS stack |

---

## Prerequisites

- AWS account with IAM permissions to create VPC, EC2, S3, IAM, RDS, and (for Module 13) Glue jobs (use a sandbox account)
- AWS CLI configured (`aws configure` or SSO)
- Terraform **1.5+** ([install guide](https://developer.hashicorp.com/terraform/install))
- Git, a code editor, and comfort with a Linux shell
- Optional later: Go 1.21+ (Terratest), Docker, `tflint`, `tfsec`/`checkov`

### Cost warning

Several projects create **billable** AWS resources (NAT Gateway, RDS, ALB, ECS, ElastiCache). Prefer `t3.micro` / Fargate small sizes, destroy when done, and keep work in a dedicated sandbox account with billing alarms.

---

## How each module is organized

```text
modules/NN-name/
├── README.md          # Concepts, diagrams, code, best practices, interview Q&A, case study
├── project/           # Hands-on Terraform you can init / plan / apply
├── exercises/         # Assignments with hints
└── solutions/         # Reference answers (where provided)
```

Every major topic aims to cover:

1. Concept explanation  
2. Why the feature exists  
3. Real-world use cases  
4. Architecture diagrams (ASCII)  
5. Step-by-step examples  
6. Terraform code  
7. Production best practices  
8. Common mistakes and troubleshooting  
9. Interview questions  
10. Hands-on exercises  
11. Mini project  
12. Related advanced topics  

---

## Suggested learning path

### Week-style pacing (self-paced)

1. **Foundation** — Modules 1–3. Finish every project. Do not skip state mental models.
2. **Core platform skills** — Modules 4–6. Remote state first; then modules; then AWS composition.
3. **Production habits** — Modules 7–9. Repo layout, least privilege, automated validation.
4. **Scale** — Modules 10–12. Refactoring, tooling choices, multi-account design.
5. **Data platform** — Module 13. Config-driven Glue jobs and environment-mapped CI.
6. **Delivery** — Module 14. Monorepo GitHub Actions, OIDC, Terraform roots, EKS deploys.
7. **Prove it** — Capstone. Treat it like a take-home for a platform/DevOps role.

### Daily workflow for each module

```bash
# 1. Read the module README
# 2. Enter the project
cd modules/0N-.../project

# 3. Configure
cp terraform.tfvars.example terraform.tfvars   # if present
# edit values; never commit secrets

# 4. Run the loop
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply

# 5. Clean up
terraform destroy
```

---

## Repository layout

```text
.
├── README.md                 # You are here
├── LEARNING_PATH.md          # Detailed path + checkpoints
├── modules/                  # Lessons 01–12
├── capstone/                 # Final production platform
├── appendices/
│   ├── cheatsheet.md
│   ├── glossary.md
│   ├── interview-master-list.md
│   └── resources.md
└── exercises/                # Extra cross-links for later modules
```

---

## Production principles used in this course

- **Remote state + locking** before team collaboration  
- **Modules** for reuse; **roots per environment/account** for blast-radius control  
- **No secrets in Git** — Secrets Manager / SSM / CI secrets  
- **Plan in PR, apply with policy** — GitOps, not laptop production applies  
- **Least privilege IAM** and encryption by default  
- **Validate early** — `fmt`, `validate`, TFLint, Checkov/tfsec, Terratest  
- **Tag everything** for cost, ownership, and compliance  

---

## Appendices

- [CLI & HCL cheatsheet](appendices/cheatsheet.md)
- [Glossary](appendices/glossary.md)
- [Interview master list](appendices/interview-master-list.md)
- [Further resources](appendices/resources.md)

---

## Quick start (Module 1)

```bash
cd modules/01-iac-fundamentals/project
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
# terraform apply   # only in a sandbox account
# terraform destroy # when finished
```

Then continue to [Module 2](modules/02-terraform-basics/).

---

## License / intent

Educational material for learning Terraform on AWS. Examples prefer clarity over every edge-case hardening control. Before using patterns in a real company environment, adapt them to your org’s account strategy, compliance, and cost constraints.
