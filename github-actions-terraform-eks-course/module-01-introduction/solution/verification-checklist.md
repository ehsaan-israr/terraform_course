# Module 01 Verification Checklist

Mark each item when verified. All boxes must be checked before Module 02.

## AWS

- [ ] `aws sts get-caller-identity` returns account ID and ARN
- [ ] Default region is `us-east-1` (or documented alternative)
- [ ] Using sandbox / non-production credentials
- [ ] No access keys committed to Git

## CLI Tools

- [ ] `git --version` >= 2.30
- [ ] `aws --version` shows CLI v2
- [ ] `terraform version` >= 1.5.0
- [ ] `kubectl version --client` >= 1.28
- [ ] `docker version` shows client and server

## Functional Tests

- [ ] `docker run --rm hello-world` succeeds
- [ ] `terraform -help` runs without error
- [ ] `kubectl config view` runs (empty config is OK)

## Git Configuration

- [ ] `git config user.name` is set
- [ ] `git config user.email` is set
- [ ] Course repository cloned locally

## Scripts

- [ ] `./scripts/check-prerequisites.sh` reviewed output
- [ ] `./scripts/verify-toolchain.sh` exits 0

## Notes

| Item | Value |
| --- | --- |
| Date verified | |
| AWS Account ID | |
| AWS Profile | |
| OS / Version | |
| Issues encountered | |
