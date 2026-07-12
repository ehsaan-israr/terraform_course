#!/usr/bin/env bash
# Install course toolchain on Debian/Ubuntu-based Linux.
# Usage: sudo ./install-linux.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Re-run with sudo for system package installation."
  exit 1
fi

echo "==> Updating package index..."
apt-get update -qq

echo "==> Installing bootstrap packages..."
apt-get install -y -qq curl unzip gnupg software-properties-common apt-transport-https ca-certificates lsb-release

echo "==> Adding HashiCorp Terraform repository..."
install -d -m 0755 /usr/share/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/hashicorp.list

echo "==> Adding Kubernetes kubectl repository..."
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update -qq

echo "==> Installing git, terraform, kubectl..."
apt-get install -y -qq git terraform kubectl

echo "==> Installing AWS CLI v2..."
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  CLI_ARCH="x86_64" ;;
  aarch64) CLI_ARCH="aarch64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${CLI_ARCH}.zip" -o /tmp/awscliv2.zip
unzip -q -o /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/aws /tmp/awscliv2.zip

echo "==> Docker (engine) — install if missing..."
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  usermod -aG docker "${SUDO_USER:-$USER}" 2>/dev/null || true
  echo "Log out and back in for docker group membership, or run: newgrp docker"
else
  echo "Docker already installed."
fi

echo ""
echo "Installation complete. Next steps:"
echo "  1. aws configure   (or aws sso login)"
echo "  2. ./verify-toolchain.sh"
