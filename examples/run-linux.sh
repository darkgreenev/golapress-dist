#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

if [[ -f ".env" ]]; then
  set -a
  # shellcheck disable=SC1091
  . ".env"
  set +a
fi

export APP_ENV="${APP_ENV:-production}"
export APP_PORT="${APP_PORT:-8076}"
export APP_URL="${APP_URL:-http://localhost:${APP_PORT}}"
export DB_DRIVER="${DB_DRIVER:-sqlite}"
export DB_DSN="${DB_DSN:-file:./data/golapress.db?_foreign_keys=on}"
export MEDIA_DIR="${MEDIA_DIR:-./data/media}"

mkdir -p data/media themes plugins
exec ./bin/golapress
