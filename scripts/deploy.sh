#!/usr/bin/env bash
# Deploys a new image to the target node via SSH.
# Runs on the self-hosted runner as part of the CD pipeline.
#
# Required env vars (set as GitHub Secrets):
#   SSH_PRIVATE_KEY  - Private SSH key for connecting to the target node
#   TARGET_HOST      - Hostname or IP of the target node
#   TARGET_USER      - SSH user on the target node (must be 'deploy')
#   IMAGE            - Full image reference to deploy (e.g. ghcr.io/owner/repo:v1.0)
#   GHCR_USERNAME    - GitHub username for GHCR authentication
#   GHCR_TOKEN       - Token with read:packages scope (use GITHUB_TOKEN in CI)
set -euo pipefail

: "${SSH_PRIVATE_KEY:?SSH_PRIVATE_KEY is required}"
: "${TARGET_HOST:?TARGET_HOST is required}"
: "${TARGET_USER:?TARGET_USER is required}"
: "${IMAGE:?IMAGE is required}"
: "${GHCR_USERNAME:?GHCR_USERNAME is required}"
: "${GHCR_TOKEN:?GHCR_TOKEN is required}"

# Set up ephemeral SSH key
install -d -m 700 ~/.ssh
printf '%s' "${SSH_PRIVATE_KEY}" | tr -d '\r' > ~/.ssh/deploy_key
chmod 600 ~/.ssh/deploy_key

rssh() {
    ssh -i ~/.ssh/deploy_key \
        -o StrictHostKeyChecking=no \
        -o BatchMode=yes \
        -o ConnectTimeout=30 \
        "${TARGET_USER}@${TARGET_HOST}" "$@"
}

echo "Authenticating Docker registry on target node..."
printf '%s' "${GHCR_TOKEN}" \
    | rssh docker login ghcr.io -u "${GHCR_USERNAME}" --password-stdin

echo "Pulling image: ${IMAGE}"
rssh docker pull "${IMAGE}"

echo "Updating deployment and restarting service..."
rssh sudo /usr/local/bin/deploy-mywebapp "${IMAGE}"

echo "Waiting for service to become ready..."
sleep 15

echo "Deployment complete."
