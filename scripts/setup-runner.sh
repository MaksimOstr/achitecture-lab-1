#!/usr/bin/env bash
# Sets up a fresh Ubuntu 24.04 VM as a GitHub Actions self-hosted runner.
# Installs all prerequisites and the runner binary, but does NOT register it —
# registration requires a token that must NOT be committed to the repository.
# After running this script, register the runner manually (see instructions below).
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "Run this script as root or with sudo." >&2
    exit 1
fi

RUNNER_VERSION="2.322.0"
RUNNER_ARCH="x64"
RUNNER_DIR=/opt/actions-runner
RUNNER_USER=runner

# ── System packages ──────────────────────────────────────────────────────────

apt-get update
apt-get install -y \
    curl \
    git \
    jq \
    ca-certificates \
    gnupg \
    lsb-release \
    openssh-client \
    unzip

# Docker CE (needed to push images and run docker commands)
if ! command -v docker >/dev/null 2>&1; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    # shellcheck disable=SC1091
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
        | tee /etc/apt/sources.list.d/docker.list >/dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
fi

systemctl enable --now docker

# ── Runner user ──────────────────────────────────────────────────────────────

if ! id "${RUNNER_USER}" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "${RUNNER_USER}"
fi
usermod -aG docker "${RUNNER_USER}"

# ── Download runner ──────────────────────────────────────────────────────────

RUNNER_TGZ="actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_TGZ}"

install -d -m 0755 -o "${RUNNER_USER}" -g "${RUNNER_USER}" "${RUNNER_DIR}"
curl -fsSL "${RUNNER_URL}" -o "/tmp/${RUNNER_TGZ}"
tar -xzf "/tmp/${RUNNER_TGZ}" -C "${RUNNER_DIR}"
chown -R "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_DIR}"
rm "/tmp/${RUNNER_TGZ}"

echo ""
echo "============================================================"
echo "  Runner prerequisites installed to ${RUNNER_DIR}"
echo "============================================================"
echo ""
echo "MANUAL STEP — register the runner (do NOT commit the token):"
echo ""
echo "  sudo -u ${RUNNER_USER} ${RUNNER_DIR}/config.sh \\"
echo "    --url https://github.com/OWNER/REPO \\"
echo "    --token <REGISTRATION_TOKEN> \\"
echo "    --name my-runner \\"
echo "    --labels self-hosted,linux \\"
echo "    --unattended"
echo ""
echo "Then install and start as a system service:"
echo ""
echo "  cd ${RUNNER_DIR} && ./svc.sh install ${RUNNER_USER}"
echo "  ./svc.sh start"
echo ""
echo "Get a registration token from:"
echo "  https://github.com/OWNER/REPO/settings/actions/runners/new"
echo ""
echo "IMPORTANT: Stop and delete this VM after the lab is complete"
echo "to prevent unauthorised use of the runner."
