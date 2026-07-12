# Module 01 Exercise: Local Toolchain Setup

## Objective

Install, configure, and verify every CLI tool required for this course without using the provided solution scripts as a copy-paste shortcut. You must demonstrate that your workstation can authenticate to AWS and run container workloads locally.

---

## Requirements

1. Install the following tools meeting minimum versions:

   | Tool | Minimum Version |
   | --- | --- |
   | Git | 2.30 |
   | AWS CLI | 2.0 |
   | Terraform | 1.5 |
   | kubectl | 1.28 |
   | Docker | 24.0 |

2. Configure AWS credentials for a sandbox account in region `us-east-1`.
3. Document your installation method for each tool (package manager, direct download, version manager).
4. Create a personal verification checklist and mark each item pass/fail.

---

## Constraints

- Do **not** use production AWS accounts or root IAM credentials.
- Do **not** commit AWS access keys or secrets to Git.
- Use `us-east-1` as the default region unless your organization standardizes on another region (document the choice).
- WSL2 users must run Docker inside WSL2 or connect to Docker Desktop with WSL integration enabled.

---

## Tasks

### Task 1: AWS Authentication

1. Configure AWS CLI using either access keys or SSO.
2. Run `aws sts get-caller-identity` and record the Account ID and ARN.
3. Set default region to `us-east-1` in `~/.aws/config`.

### Task 2: Install Infrastructure and Kubernetes CLIs

1. Install Terraform >= 1.5 and verify with `terraform version`.
2. Install kubectl >= 1.28 and verify with `kubectl version --client`.
3. Ensure `terraform` and `kubectl` are on your `PATH`.

### Task 3: Install and Test Docker

1. Install Docker Engine or Docker Desktop.
2. Run `docker run --rm hello-world` successfully.
3. Confirm `docker ps` works without `sudo` (Linux) or with Docker Desktop running (macOS/Windows).

### Task 4: Git Configuration

1. Verify Git >= 2.30.
2. Set `user.name` and `user.email` for commits.
3. Clone this course repository (or confirm you already have it).

### Task 5: Build a Verification Script

Write a shell script named `my-verify-toolchain.sh` in your home directory or a personal notes folder that:

1. Checks each tool exists on `PATH`.
2. Prints version information.
3. Calls `aws sts get-caller-identity`.
4. Exits `0` if all checks pass, `1` otherwise.

Do not place this script in the course `solution/` folder.

### Task 6: Environment Documentation

Create a short `MY-SETUP.md` file (personal notes, not committed) containing:

- OS and version
- Installation commands used
- AWS profile name
- Any issues encountered and how you resolved them

---

## Expected Deliverables

| Deliverable | Location |
| --- | --- |
| Working AWS CLI session | Terminal output screenshot or log |
| `my-verify-toolchain.sh` | Your personal directory |
| `MY-SETUP.md` | Your personal notes |
| Completed verification checklist | Your personal notes |

---

## Validation Checklist

Use this checklist to confirm you are ready for Module 02. Every item must be checked before proceeding.

- [ ] `aws sts get-caller-identity` succeeds and shows expected account
- [ ] Default AWS region is `us-east-1` (or documented alternative)
- [ ] `terraform version` reports >= 1.5.0
- [ ] `kubectl version --client` runs without error
- [ ] `docker run --rm hello-world` completes successfully
- [ ] `git --version` reports >= 2.30
- [ ] `git config user.name` and `git config user.email` are set
- [ ] Personal `my-verify-toolchain.sh` exits with code 0
- [ ] No AWS secrets committed to any Git repository
- [ ] Docker daemon starts automatically (or you know how to start it)
- [ ] You have read the course cost warning in the root README
- [ ] You understand the high-level course architecture diagram

---

**When finished:** Proceed to [Module 02](../module-02-terraform/). Compare your work with `solution/` only after completing all tasks.
