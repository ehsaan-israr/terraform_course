#!/usr/bin/env bash
# Install course toolchain on macOS via Homebrew.
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install from https://brew.sh"
  exit 1
fi

echo "==> Updating Homebrew..."
brew update

echo "==> Installing Git, AWS CLI, kubectl..."
brew install git awscli kubectl

echo "==> Installing Terraform from HashiCorp tap..."
brew tap hashicorp/tap 2>/dev/null || true
brew install hashicorp/tap/terraform

echo ""
echo "==> Docker"
if command -v docker >/dev/null 2>&1; then
  echo "Docker CLI found."
else
  echo "Install Docker Desktop manually: https://www.docker.com/products/docker-desktop/"
  echo "Or: brew install --cask docker"
fi

echo ""
echo "Installation complete. Next steps:"
echo "  1. Start Docker Desktop"
echo "  2. aws configure   (or aws sso login)"
echo "  3. ./verify-toolchain.sh"
