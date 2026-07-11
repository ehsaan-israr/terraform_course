#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_DIR="${ROOT_DIR}/modules/s3_bucket"

echo "==> terraform fmt"
terraform -chdir="${ROOT_DIR}" fmt -check -recursive

echo "==> terraform init"
terraform -chdir="${MODULE_DIR}" init -backend=false -input=false

echo "==> terraform validate"
terraform -chdir="${MODULE_DIR}" validate

if command -v tflint >/dev/null 2>&1; then
  echo "==> tflint init"
  (cd "${ROOT_DIR}" && tflint --init)

  echo "==> tflint recursive"
  (cd "${ROOT_DIR}" && tflint --recursive)
else
  echo "==> tflint not installed; skipping lint step"
fi

