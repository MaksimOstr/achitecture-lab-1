#!/usr/bin/env bash
# Verifies that the application deployed correctly on the target node.
# Runs on the self-hosted runner after the deploy step.
#
# Required env vars:
#   SSH_PRIVATE_KEY  - Private SSH key for connecting to the target node
#   TARGET_HOST      - Hostname or IP of the target node
#   TARGET_USER      - SSH user on the target node
set -euo pipefail

: "${SSH_PRIVATE_KEY:?SSH_PRIVATE_KEY is required}"
: "${TARGET_HOST:?TARGET_HOST is required}"
: "${TARGET_USER:?TARGET_USER is required}"

mkdir -p ~/.ssh
chmod 700 ~/.ssh
printf '%s\n' "${SSH_PRIVATE_KEY}" > ~/.ssh/deploy_key
chmod 600 ~/.ssh/deploy_key

rssh() {
    ssh -i ~/.ssh/deploy_key \
        -o StrictHostKeyChecking=no \
        -o BatchMode=yes \
        -o ConnectTimeout=30 \
        "${TARGET_USER}@${TARGET_HOST}" "$@"
}

FAILED=0

check() {
    local desc="$1"
    shift
    if "$@"; then
        echo "PASS: ${desc}"
    else
        echo "FAIL: ${desc}"
        FAILED=1
    fi
}

echo "=== Verifying deployment on ${TARGET_HOST} ==="

# Service health
check "mywebapp systemd service is active" \
    rssh systemctl is-active mywebapp

check "nginx systemd service is active" \
    rssh systemctl is-active nginx

# Direct app port (bypasses nginx)
check "app responds on port 5200 /health/alive" \
    rssh curl -sf http://127.0.0.1:5200/health/alive -o /dev/null

check "app responds on port 5200 /health/ready" \
    rssh curl -sf http://127.0.0.1:5200/health/ready -o /dev/null

# Through nginx
check "nginx proxies GET /" \
    rssh curl -sf http://127.0.0.1/ -o /dev/null

check "nginx proxies GET /notes" \
    rssh curl -sf http://127.0.0.1/notes -o /dev/null

# nginx must NOT expose /health/* (requirement from lab 1)
HEALTH_STATUS="$(rssh curl -o /dev/null -w '%{http_code}' \
    http://127.0.0.1/health/alive || true)"
if [[ "${HEALTH_STATUS}" == "200" ]]; then
    echo "FAIL: nginx exposes /health/alive — it must be blocked"
    FAILED=1
else
    echo "PASS: nginx blocks /health/alive (HTTP ${HEALTH_STATUS})"
fi

# nginx config syntax
check "nginx -t config test passes" \
    rssh sudo nginx -t

echo ""
if [[ "${FAILED}" -ne 0 ]]; then
    echo "=== Verification FAILED ==="
    exit 1
fi

echo "=== Verification PASSED ==="
