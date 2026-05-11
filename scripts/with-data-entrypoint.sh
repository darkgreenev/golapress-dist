#!/usr/bin/env bash
set -e

# Ensure MySQL directories have correct permissions
mkdir -p /var/run/mysqld
chown mysql:mysql /var/run/mysqld

# Start MySQL service
echo "Starting MySQL..."
service mysql start

# Wait for MySQL to be ready
echo "Waiting for MySQL to start..."
until mysqladmin ping >/dev/null 2>&1; do
  sleep 1
done

# Database credentials from environment variables or defaults
MYSQL_DATABASE=${MYSQL_DATABASE:-golapress_trial}
MYSQL_USER=${MYSQL_USER:-golapress}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-golapress}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin12345}
APP_HOST=${APP_HOST:-0.0.0.0}
DB_DRIVER=${DB_DRIVER:-mysql}
DB_DSN=${DB_DSN:-${MYSQL_USER}:${MYSQL_PASSWORD}@tcp(127.0.0.1:3306)/${MYSQL_DATABASE}?parseTime=true&charset=utf8mb4,utf8}

echo "Initializing MySQL database and user..."
mysql -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
mysql -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

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

# Final configuration of .env
echo "Configuring environment..."
cd /app
sed -i "s|DB_DRIVER=sqlite|DB_DRIVER=${DB_DRIVER}|" .env
sed -i -E "s|DB_DSN=file:\\./([^[:space:]]*/)?data/golapress\\.db\\?_foreign_keys=on|DB_DSN=${DB_DSN//&/\\&}|" .env
sed -i "s|ADMIN_PASSWORD=change-me-in-real-deployments|ADMIN_PASSWORD=${ADMIN_PASSWORD}|" .env
if ! grep -q "APP_HOST=" .env; then
    echo "APP_HOST=${APP_HOST}" >> .env
else
    sed -i "s|APP_HOST=.*|APP_HOST=${APP_HOST}|" .env
fi

export DB_DRIVER
export DB_DSN
export ADMIN_PASSWORD
export APP_HOST

# Run the application
echo "Starting goLaPress Trial..."
exec ./golapress
