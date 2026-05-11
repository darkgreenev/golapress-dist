#!/usr/bin/env bash
set -e

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker is not installed. Please install Docker to run the application."
    exit 1
fi

SITE_DIR="$(pwd)"
DATA_DIR="$SITE_DIR/data"
THEMES_DIR="$SITE_DIR/themes"
PLUGINS_DIR="$SITE_DIR/plugins"
mkdir -p "$DATA_DIR" "$THEMES_DIR" "$PLUGINS_DIR"

echo "Building goLaPress standard image..."
docker build -t golapress-standard -f Dockerfile.standard .

echo "----------------------------------------------------------"
echo "Starting goLaPress standard container..."
echo "Site directory: $SITE_DIR"
echo "Data directory: $DATA_DIR"
echo "Themes directory: $THEMES_DIR"
echo "Plugins directory: $PLUGINS_DIR"
echo "Default database: MySQL (Requires server at host.docker.internal)"
echo "To use SQLite, add: -e DB_DRIVER=sqlite -e DB_DSN=file:/app/data/golapress.db?_foreign_keys=on"
echo "Default admin login: admin@example.com / admin12345"
echo "Access at: http://localhost:8076"
echo "----------------------------------------------------------"

docker run -it \
    -p 8076:8076 \
    -e APP_SITE_DIR=/app \
    -v "$DATA_DIR":/app/data \
    -v "$THEMES_DIR":/app/themes \
    -v "$PLUGINS_DIR":/app/plugins \
    golapress-standard
