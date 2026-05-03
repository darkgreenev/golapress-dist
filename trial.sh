#!/usr/bin/env bash
set -e

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker is not installed. Please install Docker to run the trial."
    exit 1
fi

echo "Building goLaPress trial image..."
docker build -t golapress-trial -f Dockerfile.trial .

echo "----------------------------------------------------------"
echo "Starting goLaPress trial container..."
echo "Default admin login: admin@example.com / admin12345"
echo "Access at: http://localhost:8076"
echo "----------------------------------------------------------"

docker run -it \
    -p 8076:8076 \
    -e MYSQL_DATABASE=golapress_trial \
    -e MYSQL_USER=golapress \
    -e MYSQL_PASSWORD=golapress \
    -e ADMIN_PASSWORD=admin12345 \
    golapress-trial
