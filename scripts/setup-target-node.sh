#!/usr/bin/env bash
# Sets up a fresh Ubuntu 24.04 VM as the deployment target node.
# Installs Docker CE, nginx, PostgreSQL, creates users, configures services.
# Passwords for DB and deploy SSH key are provided via environment variables.
#
# Required env vars:
#   MYWEBAPP_DB_PASSWORD   - PostgreSQL password for the mywebapp user
#   DEPLOY_SSH_PUBLIC_KEY  - Public key placed in deploy user's authorized_keys
#
# Optional env vars:
#   REPO_ROOT              - Path to repo checkout (default: script's parent dir)
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "Run this script as root or with sudo." >&2
    exit 1
fi

: "${MYWEBAPP_DB_PASSWORD:?MYWEBAPP_DB_PASSWORD is required}"
: "${DEPLOY_SSH_PUBLIC_KEY:?DEPLOY_SSH_PUBLIC_KEY is required}"

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DB_NAME=mywebapp
DB_USER=mywebapp
DB_HOST=127.0.0.1
APP_ETC=/etc/mywebapp
DEPLOY_USER=deploy

# ── Packages ────────────────────────────────────────────────────────────────

apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release nginx postgresql

# Docker CE
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

# ── Deploy user ──────────────────────────────────────────────────────────────

if ! id "${DEPLOY_USER}" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "${DEPLOY_USER}"
fi
usermod -aG docker "${DEPLOY_USER}"

install -d -m 0700 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" "/home/${DEPLOY_USER}/.ssh"
printf '%s\n' "${DEPLOY_SSH_PUBLIC_KEY}" \
    > "/home/${DEPLOY_USER}/.ssh/authorized_keys"
chmod 0600 "/home/${DEPLOY_USER}/.ssh/authorized_keys"
chown "${DEPLOY_USER}:${DEPLOY_USER}" "/home/${DEPLOY_USER}/.ssh/authorized_keys"

# Allow deploy user to run the deployment helper as root without a password
cat > /etc/sudoers.d/deploy-mywebapp <<'EOF'
deploy ALL=(ALL) NOPASSWD: /usr/local/bin/deploy-mywebapp
EOF
chmod 0440 /etc/sudoers.d/deploy-mywebapp

# ── App directories and env file ─────────────────────────────────────────────

install -d -m 0755 "${APP_ETC}"

DB_PORT="$(sudo -u postgres psql -Atqc "SHOW port;" 2>/dev/null || echo 5432)"

cat > "${APP_ETC}/env" <<EOF
MYWEBAPP_IMAGE=ghcr.io/OWNER/REPO:latest
MYWEBAPP_DB_URL=jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}
MYWEBAPP_DB_USERNAME=${DB_USER}
MYWEBAPP_DB_PASSWORD=${MYWEBAPP_DB_PASSWORD}
MYWEBAPP_SERVER_ADDRESS=127.0.0.1
MYWEBAPP_SERVER_PORT=5200
EOF
chmod 0640 "${APP_ETC}/env"
chown root:docker "${APP_ETC}/env"

# ── Deployment helper ────────────────────────────────────────────────────────

install -m 0755 "${REPO_ROOT}/deploy/templates/deploy-mywebapp" \
    /usr/local/bin/deploy-mywebapp

# ── PostgreSQL ───────────────────────────────────────────────────────────────

POSTGRES_CONF="$(sudo -u postgres psql -Atqc "SHOW config_file;")"
POSTGRES_HBA="$(dirname "${POSTGRES_CONF}")/pg_hba.conf"

sed -i "s/^#\?listen_addresses.*/listen_addresses = '127.0.0.1'/" "${POSTGRES_CONF}"

if ! grep -q "^host[[:space:]]\+${DB_NAME}[[:space:]]\+${DB_USER}[[:space:]]\+${DB_HOST}/32[[:space:]]\+scram-sha-256$" "${POSTGRES_HBA}"; then
    printf '\nhost %s %s %s/32 scram-sha-256\n' "${DB_NAME}" "${DB_USER}" "${DB_HOST}" \
        >> "${POSTGRES_HBA}"
fi

systemctl restart postgresql
DB_PORT="$(sudo -u postgres psql -Atqc "SHOW port;")"

sudo -u postgres psql -v ON_ERROR_STOP=1 <<PSQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${DB_USER}') THEN
    CREATE ROLE ${DB_USER} LOGIN PASSWORD '${MYWEBAPP_DB_PASSWORD}';
  ELSE
    ALTER ROLE ${DB_USER} WITH PASSWORD '${MYWEBAPP_DB_PASSWORD}';
  END IF;
END
\$\$;
PSQL

if ! sudo -u postgres psql -Atqc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1; then
    sudo -u postgres createdb -O "${DB_USER}" "${DB_NAME}"
fi

# Update DB_PORT in env file now that we know the real value
sed -i "s|:5432/|:${DB_PORT}/|" "${APP_ETC}/env"

# ── Nginx ────────────────────────────────────────────────────────────────────

install -m 0644 "${REPO_ROOT}/deploy/templates/nginx-mywebapp-target.conf" \
    /etc/nginx/sites-available/mywebapp
ln -sf /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/mywebapp
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl enable --now nginx

# ── Systemd service ──────────────────────────────────────────────────────────

install -m 0644 "${REPO_ROOT}/deploy/templates/mywebapp-docker.service" \
    /etc/systemd/system/mywebapp.service
systemctl daemon-reload
systemctl enable mywebapp

# ── Docker daemon ────────────────────────────────────────────────────────────

systemctl enable --now docker

echo ""
echo "Target node setup complete."
echo "Update MYWEBAPP_IMAGE in ${APP_ETC}/env to the actual ghcr.io image path."
echo "Then run: systemctl start mywebapp"
