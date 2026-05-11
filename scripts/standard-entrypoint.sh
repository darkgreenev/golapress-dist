#!/usr/bin/env bash
set -e

# In the distribution repo, latest.json is already in the root
# If it's not there (e.g. running from private repo), we might need to fetch it
if [ ! -f "latest.json" ] && [ ! -d "golapress-dist" ]; then
    echo "Fetching distribution metadata..."
    git clone --depth 1 https://github.com/darkgreenev/golapress-dist.git
    cd golapress-dist
fi

# Extract the binary from the latest release
echo "Extracting latest binary for Linux..."
LATEST_JSON="latest.json"
if [ ! -f "$LATEST_JSON" ] && [ -d "golapress-dist" ]; then
    LATEST_JSON="golapress-dist/latest.json"
fi

BINARY_URL=$(grep -o '"linux_amd64": "[^"]*' "$LATEST_JSON" | cut -d'"' -f4)
if [ -z "$BINARY_URL" ]; then
    echo "Error: Could not find binary URL in $LATEST_JSON"
    exit 1
fi

curl -L -o golapress.tar.gz "$BINARY_URL"
tar -xzf golapress.tar.gz

# Move binary and assets to the app root
EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "golapress-linux-*" | head -n 1)
cp "$EXTRACTED_DIR/golapress" /app/
cp "$EXTRACTED_DIR/.env.example" /app/.env

# Ensure site directories exist
mkdir -p /app/data/media /app/themes /app/plugins

# Final configuration of .env
echo "Configuring environment..."
cd /app

# Set database driver and DSN from environment or defaults
APP_HOST=${APP_HOST:-0.0.0.0}
DB_DRIVER=${DB_DRIVER:-mysql}
DB_DSN=${DB_DSN:-golapress:golapress@tcp(host.docker.internal:3306)/golapress?parseTime=true&charset=utf8mb4,utf8}

sed -i -E "s|^DB_DRIVER=.*|DB_DRIVER=${DB_DRIVER}|" .env
sed -i -E "s|^DB_DSN=.*|DB_DSN=${DB_DSN//&/\\&}|" .env

if ! grep -q "APP_HOST=" .env; then
    echo "APP_HOST=${APP_HOST}" >> .env
else
    sed -i "s|APP_HOST=.*|APP_HOST=${APP_HOST}|" .env
fi

export APP_HOST
export DB_DRIVER
export DB_DSN

# Run the application
echo "Starting goLaPress..."
exec ./golapress
