#!/usr/bin/env bash
set -e

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker is not installed. Please install Docker to run the trial."
    exit 1
fi

echo "Building goLaPress withData image..."
docker build -t golapress-with-data -f Dockerfile.withData .

echo "----------------------------------------------------------"
echo "Starting goLaPress withData container..."
echo "Internal MySQL: Included and configured automatically."
echo "Default admin login: admin@example.com / admin12345"
echo "To pass custom settings (e.g. AI key):"
echo "  docker run -it -p 8076:8076 -e RAPIDAPI_KEY=your_key golapress-with-data"
echo "Access at: http://localhost:8076"
echo "----------------------------------------------------------"

docker run -it \
    -p 8076:8076 \
    ${DOCKER_OPTS:-} \
    golapress-with-data
