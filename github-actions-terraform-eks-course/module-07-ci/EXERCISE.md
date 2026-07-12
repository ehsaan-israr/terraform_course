# Module 07 Exercise — CI Pipeline with ECR

## Objective

Implement a GitHub Actions CI workflow for a Node.js API that runs tests, builds a Docker image, and pushes to Amazon ECR in `us-east-1` using **OIDC authentication** (document access keys as an alternative).

---

## Requirements

1. **Application** (`src/server.js`):
   - Express (or native Node HTTP) server on port 3000
   - `GET /` returns a welcome message
   - `GET /health` returns JSON `{ "status": "healthy" }` with HTTP 200

2. **Tests** (`test/server.test.js`):
   - At least two tests using Node's built-in test runner or Jest
   - Tests run with `npm test` in CI without manual steps

3. **Dockerfile**:
   - Multi-stage build (build → production)
   - Non-root user in final stage
   - Health check or documented probe path

4. **`.github/workflows/ci.yml`**:
   - Triggers: `push` and `pull_request` to `main`
   - Job `test`: checkout, setup Node 20, `npm ci`, `npm test`
   - Job `docker`: needs `test`, OIDC to AWS, build and push to ECR
   - Image tags: `${{ github.sha }}` and optionally `latest` on `main` only
   - Region: `us-east-1`

5. **Documentation** (`docs/aws-oidc-setup.md`):
   - IAM OIDC provider setup
   - IAM role trust policy scoped to your repo
   - ECR permissions policy
   - **Alternative:** access keys pattern (clearly marked less secure)

---

## Constraints

- Do **not** commit AWS access keys or `terraform.tfvars` with secrets.
- ECR repository name: `course-api` (or document your choice).
- Use `permissions` blocks with least privilege (`id-token: write` only where needed).
- Pin GitHub Action versions (`@v4`).
- `.dockerignore` must exclude `node_modules`, `.git`, and test artifacts.

---

## Tasks

### Task 1 — Application and tests

- [ ] Create `package.json` with `test` script
- [ ] Implement `src/server.js` with `/` and `/health`
- [ ] Write tests in `test/server.test.js`
- [ ] Verify `npm test` passes locally

### Task 2 — Container image

- [ ] Write multi-stage `Dockerfile`
- [ ] Add `.dockerignore`
- [ ] Build and run locally; curl `/health`

### Task 3 — AWS setup

- [ ] Create ECR repo `course-api` in `us-east-1`
- [ ] Configure GitHub OIDC provider and IAM role
- [ ] Add `AWS_ROLE_ARN` secret and `AWS_REGION` variable in GitHub

### Task 4 — CI workflow

- [ ] Create `.github/workflows/ci.yml` with `test` and `docker` jobs
- [ ] Push to GitHub and verify green CI run
- [ ] Confirm image appears in ECR with SHA tag

### Task 5 — Document access keys alternative

- [ ] In `docs/aws-oidc-setup.md`, document how access keys *would* be wired (without using real keys)

---

## Expected Deliverables

| Deliverable | Path |
| --- | --- |
| Node.js API | `src/server.js` |
| Tests | `test/server.test.js` |
| Dockerfile | `Dockerfile` |
| CI workflow | `.github/workflows/ci.yml` |
| AWS setup guide | `docs/aws-oidc-setup.md` |
| ECR proof | Screenshot or CLI output in README notes |

---

## Validation Checklist

- [ ] `npm test` passes locally
- [ ] CI `test` job passes on push and PR
- [ ] CI `docker` job pushes to ECR in `us-east-1`
- [ ] Image tag includes Git commit SHA
- [ ] Workflow uses OIDC (`role-to-assume`), not hardcoded keys
- [ ] `id-token: write` permission is set on docker job
- [ ] Dockerfile runs as non-root
- [ ] No secrets in Git history
- [ ] `docs/aws-oidc-setup.md` explains both OIDC and access-key patterns
- [ ] Container `/health` responds 200 when run locally

**Do not read `solution/` until all items are checked.**
