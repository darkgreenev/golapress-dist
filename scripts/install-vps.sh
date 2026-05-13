#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/install-vps.sh [--site-dir PATH] [--install-dir PATH] [--app-url URL] [--db-dsn DSN] [--db-driver mysql|sqlite] [--runtime local|docker|auto]

Installs goLaPress on a VPS without Docker by downloading the latest release
binary from golapress-dist, preparing a site directory, and either:
  - installing a systemd service when systemd is available, or
  - starting a managed background process when systemd is not available.

Optional features:
  - provision a MySQL database/user on an existing MySQL server
  - install Node.js/npm and @openai/codex for local Codex runtime

Examples:
  ./scripts/install-vps.sh \
    --site-dir /var/www/golapress \
    --app-url https://example.com

  ./scripts/install-vps.sh \
    --site-dir /var/www/golapress \
    --app-url https://example.com \
    --db-driver mysql \
    --admin-password 'use-a-long-random-password' \
    --mysql-create-db \
    --mysql-db-name golapress \
    --mysql-db-user golapress \
    --mysql-db-password 'strong-db-password' \
    --db-dsn 'golapress:secret@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8'

  ./scripts/install-vps.sh \
    --site-dir /var/www/golapress \
    --app-url https://example.com \
    --enable-codex \
    --runtime local \
    --install-codex
EOF
}

shell_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

upsert_env_file_value() {
  file="$1"
  key="$2"
  value="$3"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if grep -q "^${key}=" "$file"; then
    sed -i -E "s|^${key}=.*|${key}=${value}|" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

write_env_file() {
  file="$1"
  content="$2"
  mkdir -p "$(dirname "$file")"
  tmp="${file}.tmp"
  printf '%s' "$content" > "$tmp"
  chmod 0600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$file"
}

stop_existing_background_process() {
  pid_file="$1"
  if [ ! -f "$pid_file" ]; then
    return
  fi

  pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [ -z "$pid" ]; then
    rm -f "$pid_file"
    return
  fi

  if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$pid_file"
    return
  fi

  echo "Stopping existing goLaPress process: $pid"
  kill "$pid" 2>/dev/null || true

  waited=0
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$waited" -ge 15 ]; then
      echo "Existing goLaPress process did not exit after 15s; sending SIGKILL to $pid"
      kill -KILL "$pid" 2>/dev/null || true
      break
    fi
    sleep 1
    waited=$((waited + 1))
  done

  rm -f "$pid_file"
}

sql_string_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"
}

mysql_run() {
  local sql="$1"
  local cmd=(mysql "--user=$mysql_root_user" "--port=$mysql_root_port" "--execute=$sql")
  if [ -n "$mysql_root_host" ]; then
    cmd+=("--host=$mysql_root_host")
  fi
  if [ -n "$mysql_root_password" ]; then
    cmd+=("--password=$mysql_root_password")
  fi
  "${cmd[@]}"
}

install_codex_cli() {
  local npm_prefix=""

  if command -v codex >/dev/null 2>&1; then
    echo "Codex CLI already present: $(command -v codex)"
    return
  fi

  if ! command -v npm >/dev/null 2>&1; then
    if ! command -v apt-get >/dev/null 2>&1; then
      echo "Error: npm is not installed and apt-get is unavailable; cannot install Codex CLI automatically." >&2
      exit 1
    fi
    if [ "$(id -u)" -ne 0 ]; then
      echo "Error: automatic Codex installation requires root when npm is missing." >&2
      exit 1
    fi
    echo "Installing Node.js and npm..."
    apt-get update
    apt-get install -y nodejs npm
  fi

  echo "Installing @openai/codex..."
  if [ "$(id -u)" -eq 0 ]; then
    npm install -g @openai/codex
  else
    npm_prefix="$HOME/.local"
    mkdir -p "$npm_prefix"
    npm install -g --prefix "$npm_prefix" @openai/codex
    path_env="$npm_prefix/bin:$path_env"
    export PATH="$npm_prefix/bin:$PATH"
  fi
  if ! command -v codex >/dev/null 2>&1; then
    echo "Error: Codex CLI install finished but 'codex' is not on PATH." >&2
    exit 1
  fi
}

provision_mysql() {
  local app_db_name="$mysql_db_name"
  local app_db_user="$mysql_db_user"
  local app_db_password="$mysql_db_password"

  if [ "$db_driver" != "mysql" ]; then
    echo "Error: --mysql-create-db requires --db-driver mysql." >&2
    exit 1
  fi
  if ! command -v mysql >/dev/null 2>&1; then
    echo "Error: mysql client is required for --mysql-create-db." >&2
    exit 1
  fi
  if [ -z "$app_db_name" ] || [ -z "$app_db_user" ] || [ -z "$app_db_password" ]; then
    echo "Error: --mysql-create-db requires --mysql-db-name, --mysql-db-user, and --mysql-db-password." >&2
    exit 1
  fi
  if printf '%s' "$app_db_name" | grep -q '`'; then
    echo "Error: --mysql-db-name may not contain backticks." >&2
    exit 1
  fi

  echo "Provisioning MySQL database and user..."
  mysql_run "CREATE DATABASE IF NOT EXISTS \`$app_db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  mysql_run "CREATE USER IF NOT EXISTS $(sql_string_quote "$app_db_user")@$(sql_string_quote "$mysql_app_host") IDENTIFIED BY $(sql_string_quote "$app_db_password");"
  mysql_run "ALTER USER $(sql_string_quote "$app_db_user")@$(sql_string_quote "$mysql_app_host") IDENTIFIED BY $(sql_string_quote "$app_db_password");"
  mysql_run "GRANT ALL PRIVILEGES ON \`$app_db_name\`.* TO $(sql_string_quote "$app_db_user")@$(sql_string_quote "$mysql_app_host");"
  mysql_run "FLUSH PRIVILEGES;"

  if [ "$db_dsn" = "$default_mysql_dsn" ] || [ -z "$db_dsn" ]; then
    db_dsn="${app_db_user}:${app_db_password}@tcp(${mysql_dsn_host}:${mysql_dsn_port})/${app_db_name}?parseTime=true&charset=utf8mb4,utf8"
  fi
}

site_dir="${APP_SITE_DIR:-$HOME/golapress-site}"
if [ -n "${GOLAPRESS_INSTALL_DIR:-}" ]; then
  install_dir="$GOLAPRESS_INSTALL_DIR"
elif [ "$(id -u)" -eq 0 ]; then
  install_dir="/usr/local/bin"
else
  install_dir="$HOME/.local/bin"
fi
app_url="${APP_URL:-http://localhost:8076}"
db_driver="${DB_DRIVER:-mysql}"
default_mysql_dsn="golapress:golapress@tcp(127.0.0.1:3306)/golapress?parseTime=true&charset=utf8mb4,utf8"
db_dsn="${DB_DSN:-$default_mysql_dsn}"
runtime_mode="${CODEX_RUNTIME:-auto}"
codex_enabled="${CODEX_AI_ENABLED:-false}"
app_host="${APP_HOST:-0.0.0.0}"
app_port="${APP_PORT:-8076}"
admin_email="${ADMIN_EMAIL:-admin@example.com}"
admin_password="${ADMIN_PASSWORD:-change-me-in-real-deployments}"
admin_display_name="${ADMIN_DISPLAY_NAME:-Admin}"
path_env="${PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}"
service_name="golapress"
repo_url="https://github.com/darkgreenev/golapress-dist"
binary_name="golapress"
release_arch="linux_amd64"
use_systemd=0
install_codex_requested=0
mysql_create_db=0
mysql_root_user="${MYSQL_ROOT_USER:-root}"
mysql_root_password="${MYSQL_ROOT_PASSWORD:-}"
mysql_root_host="${MYSQL_ROOT_HOST:-localhost}"
mysql_root_port="${MYSQL_ROOT_PORT:-3306}"
mysql_app_host="${MYSQL_APP_HOST:-127.0.0.1}"
mysql_db_name="${MYSQL_DB_NAME:-}"
mysql_db_user="${MYSQL_DB_USER:-}"
mysql_db_password="${MYSQL_DB_PASSWORD:-}"
mysql_dsn_host="${MYSQL_DSN_HOST:-127.0.0.1}"
mysql_dsn_port="${MYSQL_DSN_PORT:-3306}"

while [ $# -gt 0 ]; do
  case "$1" in
    --site-dir)
      site_dir="${2:-}"; shift 2 ;;
    --install-dir)
      install_dir="${2:-}"; shift 2 ;;
    --app-url)
      app_url="${2:-}"; shift 2 ;;
    --db-dsn)
      db_dsn="${2:-}"; shift 2 ;;
    --db-driver)
      db_driver="${2:-}"; shift 2 ;;
    --runtime)
      runtime_mode="${2:-}"; shift 2 ;;
    --enable-codex)
      codex_enabled="true"; shift ;;
    --install-codex)
      install_codex_requested=1; shift ;;
    --admin-email)
      admin_email="${2:-}"; shift 2 ;;
    --admin-password)
      admin_password="${2:-}"; shift 2 ;;
    --admin-display-name)
      admin_display_name="${2:-}"; shift 2 ;;
    --mysql-create-db)
      mysql_create_db=1; shift ;;
    --mysql-root-user)
      mysql_root_user="${2:-}"; shift 2 ;;
    --mysql-root-password)
      mysql_root_password="${2:-}"; shift 2 ;;
    --mysql-root-host)
      mysql_root_host="${2:-}"; shift 2 ;;
    --mysql-root-port)
      mysql_root_port="${2:-}"; shift 2 ;;
    --mysql-app-host)
      mysql_app_host="${2:-}"; shift 2 ;;
    --mysql-db-name)
      mysql_db_name="${2:-}"; shift 2 ;;
    --mysql-db-user)
      mysql_db_user="${2:-}"; shift 2 ;;
    --mysql-db-password)
      mysql_db_password="${2:-}"; shift 2 ;;
    --mysql-dsn-host)
      mysql_dsn_host="${2:-}"; shift 2 ;;
    --mysql-dsn-port)
      mysql_dsn_port="${2:-}"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required." >&2
  exit 1
fi
if ! command -v tar >/dev/null 2>&1; then
  echo "Error: tar is required." >&2
  exit 1
fi
if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required." >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64|amd64)
    release_arch="linux_amd64"
    ;;
  aarch64|arm64)
    release_arch="linux_arm64"
    ;;
  *)
    echo "Error: unsupported CPU architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

if [ "$mysql_create_db" -eq 1 ]; then
  provision_mysql
fi

if [ "$install_codex_requested" -eq 1 ]; then
  install_codex_cli
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo "Fetching release metadata..."
if [ -f "latest.json" ]; then
  latest_json="$PWD/latest.json"
else
  git clone --depth 1 "$repo_url" "$tmp_dir/golapress-dist" >/dev/null 2>&1
  latest_json="$tmp_dir/golapress-dist/latest.json"
fi

binary_url="$(grep -o "\"${release_arch}\": \"[^\"]*" "$latest_json" | cut -d'"' -f4)"
if [ -z "$binary_url" ]; then
  echo "Error: could not find ${release_arch} binary URL in $latest_json" >&2
  exit 1
fi

mkdir -p "$site_dir"/data/media "$site_dir"/themes "$site_dir"/plugins
if [ ! -f "$site_dir/.gitignore" ]; then
  cat > "$site_dir/.gitignore" <<'EOF'
data/*.db
data/*.sqlite
data/*.sqlite3
data/admin.env
data/ai_*.json
data/*.log
data/sessions/
backups/
EOF
fi

echo "Downloading latest binary..."
curl -fsSL -o "$tmp_dir/golapress.tar.gz" "$binary_url"
tar -xzf "$tmp_dir/golapress.tar.gz" -C "$tmp_dir"

extracted_dir="$(find "$tmp_dir" -maxdepth 1 -type d -name 'golapress-linux-*' | head -n 1)"
if [ -z "$extracted_dir" ] || [ ! -f "$extracted_dir/$binary_name" ]; then
  echo "Error: extracted release did not contain $binary_name" >&2
  exit 1
fi

mkdir -p "$install_dir"
install -m 0755 "$extracted_dir/$binary_name" "$install_dir/$binary_name"

mkdir -p "$site_dir/data"
if [ -z "$db_dsn" ] && [ "$db_driver" = "sqlite" ]; then
  db_dsn="file:$site_dir/data/golapress.db?_foreign_keys=on"
fi
rm -f "$site_dir"/.env.bak.*
write_env_file "$site_dir/.env.example" "$(cat <<EOF
APP_NAME='goLaPress'
APP_ENV='production'
PATH=$(shell_quote "$path_env")
APP_URL=$(shell_quote "$app_url")
APP_HOST=$(shell_quote "$app_host")
APP_PORT=$(shell_quote "$app_port")
APP_SITE_DIR=$(shell_quote "$site_dir")
APP_SITE_GIT_INIT=true
APP_UPDATE_LATEST_URL='https://raw.githubusercontent.com/darkgreenev/golapress-dist/main/latest.json'
DB_DRIVER=$(shell_quote "$db_driver")
ADMIN_EMAIL=$(shell_quote "$admin_email")
ADMIN_DISPLAY_NAME=$(shell_quote "$admin_display_name")
SESSION_COOKIE_NAME='golapress_session'
SESSION_TTL='24h'
# Keep real secrets in data/runtime.env. Do not commit that file.
DB_DSN='change-me-in-data-runtime-env'
ADMIN_PASSWORD='change-me-in-data-runtime-env'
EOF
)"
write_env_file "$site_dir/.env" "$(cat <<EOF
APP_NAME='goLaPress'
APP_ENV='production'
PATH=$(shell_quote "$path_env")
APP_URL=$(shell_quote "$app_url")
APP_HOST=$(shell_quote "$app_host")
APP_PORT=$(shell_quote "$app_port")
APP_SITE_DIR=$(shell_quote "$site_dir")
APP_SITE_GIT_INIT=true
APP_UPDATE_LATEST_URL='https://raw.githubusercontent.com/darkgreenev/golapress-dist/main/latest.json'
DB_DRIVER=$(shell_quote "$db_driver")
ADMIN_EMAIL=$(shell_quote "$admin_email")
ADMIN_DISPLAY_NAME=$(shell_quote "$admin_display_name")
SESSION_COOKIE_NAME='golapress_session'
SESSION_TTL='24h'
EOF
)"
write_env_file "$site_dir/data/runtime.env" "$(cat <<EOF
DB_DSN=$(shell_quote "$db_dsn")
ADMIN_PASSWORD=$(shell_quote "$admin_password")
EOF
)"

admin_env="$site_dir/data/admin.env"
upsert_env_file_value "$admin_env" "CODEX_AI_ENABLED" "$codex_enabled"
upsert_env_file_value "$admin_env" "CODEX_RUNTIME" "$runtime_mode"

export APP_SITE_DIR="$site_dir"
export APP_URL="$app_url"
export APP_HOST="$app_host"
export APP_PORT="$app_port"
export DB_DRIVER="$db_driver"
export DB_DSN="$db_dsn"
export ADMIN_EMAIL="$admin_email"
export ADMIN_PASSWORD="$admin_password"
export ADMIN_DISPLAY_NAME="$admin_display_name"

if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ] && [ "$(id -u)" -eq 0 ]; then
  use_systemd=1
fi

if [ "$use_systemd" -eq 1 ]; then
  unit_path="/etc/systemd/system/${service_name}.service"
  cat > "$unit_path" <<EOF
[Unit]
Description=goLaPress
After=network-online.target mysql.service
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$site_dir
EnvironmentFile=$site_dir/.env
EnvironmentFile=-$site_dir/data/runtime.env
ExecStart=$install_dir/$binary_name
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable "$service_name"
  systemctl restart "$service_name"

  echo "Installed systemd service: $service_name"
  echo "Site directory: $site_dir"
  echo "Binary: $install_dir/$binary_name"
  echo "Status: systemctl status $service_name"
else
  run_script="$site_dir/run-golapress.sh"
  pid_file="$site_dir/data/golapress.pid"
  cat > "$run_script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
set -a
. "$site_dir/.env"
if [ -f "$site_dir/data/runtime.env" ]; then
  . "$site_dir/data/runtime.env"
fi
set +a
exec "$install_dir/$binary_name"
EOF
  chmod 0755 "$run_script"

  stop_existing_background_process "$pid_file"
  nohup "$run_script" > "$site_dir/data/golapress.log" 2>&1 &
  pid=$!
  echo "$pid" > "$pid_file"

  echo "Started goLaPress without systemd."
  echo "Site directory: $site_dir"
  echo "PID: $pid"
  echo "Log: $site_dir/data/golapress.log"
  echo "Stop with: kill \$(cat $site_dir/data/golapress.pid)"
fi

echo "Done."
