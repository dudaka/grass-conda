#!/bin/bash
# Script to extract build logs from a Docker container
# Usage: ./extract-build-logs.sh [container_id_or_name]

set -e

CONTAINER_ID="${1:-$(docker ps -a | grep grass-conda | head -1 | awk '{print $1}')}"

if [ -z "$CONTAINER_ID" ]; then
    echo "No container found. Please provide container ID as argument."
    exit 1
fi

echo "Extracting logs from container: $CONTAINER_ID"

# Create local log directory
mkdir -p ./build-logs

# Try to copy logs from the container
docker cp "$CONTAINER_ID:/work/build-logs/conda-build.log" ./build-logs/ 2>/dev/null || \
    echo "Note: conda-build.log not found in container"

# Also try to get conda-build logs from typical locations
docker exec "$CONTAINER_ID" bash -c "find /opt/conda/conda-bld -name '*.log' -type f" | while read logfile; do
    filename=$(basename "$logfile")
    docker cp "$CONTAINER_ID:$logfile" "./build-logs/${filename}" 2>/dev/null || true
done

echo "Logs extracted to ./build-logs/"
ls -lh ./build-logs/
