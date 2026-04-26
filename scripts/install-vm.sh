#!/usr/bin/env bash
set -euo pipefail

GRADEBOOK_N=21
APP_ROOT=/opt/mywebapp
APP_CURRENT="$APP_ROOT/current"
APP_BIN="$APP_ROOT/bin"
APP_ETC=/etc/mywebapp
APP_LOG=/var/log/mywebapp
APP_PORT_INTERNAL=15200
APP_PORT_SOCKET=5200
DB_NAME=mywebapp
DB_USER=mywebapp
DB_PASSWORD="${MYWEBAPP_DB_PASSWORD:-mywebapp}"
DB_HOST=127.0.0.1
DEFAULT_VM_USER="${DEFAULT_VM_USER:-${SUDO_USER:-}}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGING_REPO_ROOT="${MYWEBAPP_STAGING_ROOT:-/root/architecture-lab1}"
APP_SYSTEM_USER=mywebapp
IS_WSL=0

normalize_linux_files() {
  local target_root="$1"
  find "$target_root" -type f \( -name '*.sh' -o -name '*.service' -o -name '*.socket' -o -name '*.conf' -o -name '*.yaml' -o -name '*.yml' -o -name 'gradlew' \) -exec sed -i 's/\r$//' {} +
  chmod +x "$target_root/gradlew"
  find "$target_root/scripts" -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} +
}

configure_wsl_default_user() {
  local target_user="$1"

  mkdir -p /etc
  if [[ -f /etc/wsl.conf ]]; then
    if grep -q '^\[user\]$' /etc/wsl.conf; then
      if grep -q '^default=' /etc/wsl.conf; then
        sed -i "s/^default=.*/default=$target_user/" /etc/wsl.conf
      else
        sed -i "/^\[user\]$/a default=$target_user" /etc/wsl.conf
      fi
    else
      printf '\n[user]\ndefault=%s\n' "$target_user" >> /etc/wsl.conf
    fi
  else
    printf '[user]\ndefault=%s\n' "$target_user" > /etc/wsl.conf
  fi
}

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root or with sudo." >&2
  exit 1
fi

if grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=1
fi

if [[ "$IS_WSL" -eq 1 ]] && [[ "$REPO_ROOT" == /mnt/* ]] && [[ "${MYWEBAPP_REEXECED:-0}" != 1 ]]; then
  echo "Detected WSL with a Windows-mounted repository. Copying the project into the Linux filesystem..."
  rm -rf "$STAGING_REPO_ROOT"
  mkdir -p "$STAGING_REPO_ROOT"
  tar -C "$REPO_ROOT" -cf - . | tar -C "$STAGING_REPO_ROOT" -xf -
  normalize_linux_files "$STAGING_REPO_ROOT"
  echo "Re-launching deployment from $STAGING_REPO_ROOT"
  exec env \
    MYWEBAPP_REEXECED=1 \
    MYWEBAPP_STAGING_ROOT="$STAGING_REPO_ROOT" \
    MYWEBAPP_DB_PASSWORD="$DB_PASSWORD" \
    DEFAULT_VM_USER="$DEFAULT_VM_USER" \
    bash "$STAGING_REPO_ROOT/scripts/install-vm.sh"
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This automation currently supports Ubuntu/Debian systems with apt-get." >&2
  exit 1
fi

apt-get update
apt-get install -y sudo openjdk-21-jdk-headless postgresql postgresql-client nginx curl unzip netcat-openbsd

if command -v sudo >/dev/null 2>&1; then
  AS_POSTGRES=(sudo -u postgres)
else
  AS_POSTGRES=(runuser -u postgres --)
fi

create_login_user() {
  local name="$1"
  if ! id "$name" >/dev/null 2>&1; then
    if getent group "$name" >/dev/null 2>&1; then
      useradd -m -g "$name" -s /bin/bash "$name"
    else
      useradd -m -s /bin/bash "$name"
    fi
  fi
  echo "${name}:12345678" | chpasswd
  chage -d 0 "$name"
}

create_login_user student
create_login_user teacher
create_login_user operator

usermod -aG sudo student
usermod -aG sudo teacher

if ! id "$APP_SYSTEM_USER" >/dev/null 2>&1; then
  if getent group "$APP_SYSTEM_USER" >/dev/null 2>&1; then
    useradd --system --home "$APP_ROOT" --gid "$APP_SYSTEM_USER" --shell /usr/sbin/nologin "$APP_SYSTEM_USER"
  else
    useradd --system --home "$APP_ROOT" --shell /usr/sbin/nologin "$APP_SYSTEM_USER"
  fi
fi

install -d -m 0755 "$APP_ROOT" "$APP_CURRENT" "$APP_BIN" "$APP_LOG"
install -d -m 0755 "$APP_ETC"

(cd "$REPO_ROOT" && ./gradlew bootJar)

JAR_PATH="$(find "$REPO_ROOT/build/libs" -maxdepth 1 -name 'mywebapp*.jar' | head -n 1)"
if [[ -z "$JAR_PATH" ]]; then
  echo "Built jar was not found." >&2
  exit 1
fi

install -m 0644 "$JAR_PATH" "$APP_CURRENT/mywebapp.jar"
install -m 0755 "$REPO_ROOT/scripts/migrate.sh" "$APP_BIN/migrate.sh"

cat > /usr/local/bin/mywebappctl <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  start)
    systemctl enable --now mywebapp.socket
    ;;
  stop)
    systemctl stop mywebapp.socket mywebapp.service mywebapp-backend.service
    ;;
  restart)
    systemctl restart mywebapp-backend.service
    systemctl restart mywebapp.socket
    ;;
  status)
    systemctl status mywebapp.socket mywebapp.service mywebapp-backend.service --no-pager
    ;;
  *)
    echo "Usage: mywebappctl {start|stop|restart|status}" >&2
    exit 1
    ;;
esac
EOF
chmod 0755 /usr/local/bin/mywebappctl

install -m 0644 "$REPO_ROOT/deploy/templates/mywebapp-backend.service" /etc/systemd/system/mywebapp-backend.service
install -m 0644 "$REPO_ROOT/deploy/templates/mywebapp.service" /etc/systemd/system/mywebapp.service
install -m 0644 "$REPO_ROOT/deploy/templates/mywebapp.socket" /etc/systemd/system/mywebapp.socket
install -m 0440 "$REPO_ROOT/deploy/templates/operator-sudoers" /etc/sudoers.d/operator-mywebapp

install -m 0644 "$REPO_ROOT/deploy/templates/nginx-mywebapp.conf" /etc/nginx/sites-available/mywebapp
ln -sf /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/mywebapp
rm -f /etc/nginx/sites-enabled/default

POSTGRES_CONF="$("${AS_POSTGRES[@]}" psql -Atqc "SHOW config_file;")"
POSTGRES_HBA="$(dirname "$POSTGRES_CONF")/pg_hba.conf"
DB_PORT="$("${AS_POSTGRES[@]}" psql -Atqc "SHOW port;")"

sed -i "s/^#\?listen_addresses.*/listen_addresses = '127.0.0.1'/" "$POSTGRES_CONF"
if ! grep -q "^host[[:space:]]\+$DB_NAME[[:space:]]\+$DB_USER[[:space:]]\+${DB_HOST}/32[[:space:]]\+scram-sha-256$" "$POSTGRES_HBA"; then
  printf '\nhost %s %s %s/32 scram-sha-256\n' "$DB_NAME" "$DB_USER" "$DB_HOST" >> "$POSTGRES_HBA"
fi

systemctl restart postgresql
DB_PORT="$("${AS_POSTGRES[@]}" psql -Atqc "SHOW port;")"

"${AS_POSTGRES[@]}" psql -v ON_ERROR_STOP=1 <<EOF
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$DB_USER') THEN
    CREATE ROLE $DB_USER LOGIN PASSWORD '$DB_PASSWORD';
  ELSE
    ALTER ROLE $DB_USER WITH PASSWORD '$DB_PASSWORD';
  END IF;
END
\$\$;
EOF

if ! "${AS_POSTGRES[@]}" psql -Atqc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1; then
  "${AS_POSTGRES[@]}" createdb -O "$DB_USER" "$DB_NAME"
fi

sed \
  -e "s|__DB_HOST__|$DB_HOST|g" \
  -e "s|__DB_PORT__|$DB_PORT|g" \
  -e "s|__DB_PASSWORD__|$DB_PASSWORD|g" \
  "$REPO_ROOT/deploy/templates/config.yaml" > "$APP_ETC/config.yaml"
chmod 0640 "$APP_ETC/config.yaml"
chown root:"$APP_SYSTEM_USER" "$APP_ETC/config.yaml"

chown -R "$APP_SYSTEM_USER":"$APP_SYSTEM_USER" "$APP_ROOT" "$APP_LOG"

systemctl daemon-reload
systemctl enable postgresql nginx mywebapp-backend.service mywebapp.socket
systemctl restart nginx
systemctl restart mywebapp-backend.service
systemctl restart mywebapp.socket

install -o student -g student -m 0755 -d /home/student
printf '%s\n' "$GRADEBOOK_N" > /home/student/gradebook
chown student:student /home/student/gradebook
chmod 0644 /home/student/gradebook

if [[ -n "$DEFAULT_VM_USER" ]] && id "$DEFAULT_VM_USER" >/dev/null 2>&1; then
  if [[ "$DEFAULT_VM_USER" != "student" && "$DEFAULT_VM_USER" != "teacher" && "$DEFAULT_VM_USER" != "operator" ]]; then
    usermod -L "$DEFAULT_VM_USER"
  fi
fi

if [[ "$IS_WSL" -eq 1 ]]; then
  configure_wsl_default_user student
fi

nginx -t
curl --fail --silent http://127.0.0.1/ >/dev/null
curl --fail --silent http://127.0.0.1/health/alive >/dev/null && {
  echo "Warning: nginx should not expose /health/alive, but it is reachable." >&2
  exit 1
} || true
curl --fail --silent http://127.0.0.1/notes >/dev/null || true

passwd -l root

if grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
  sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
else
  echo "PermitRootLogin no" >> /etc/ssh/sshd_config
fi

systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true

echo "Deployment completed."
echo "Application backend port: $APP_PORT_INTERNAL"
echo "Socket-activated local proxy port: $APP_PORT_SOCKET"
if [[ "$IS_WSL" -eq 1 ]]; then
  echo "WSL default user was set to student. Run 'wsl --shutdown' in Windows PowerShell before the next login."
fi
