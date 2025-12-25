#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

REPO_URL="https://github.com/anji5h/home_assistant.git"
DIR_NAME="home_assistant"

echo ">>> Cloning repository..."
if [ -d "$DIR_NAME" ]; then
    echo "Directory '$DIR_NAME' already exists. Skipping clone."
else
    git clone "$REPO_URL"
fi

echo ">>> Navigating into directory..."
cd "$DIR_NAME"

echo ">>> Creating .env file..."
cat <<EOF > .env
INFLUXDB_HOST=influxdb
INFLUXDB_PORT=8086
INFLUXDB_TOKEN=CxdI9xTtdodxeOvdgkIBPXpOX7okmCof
INFLUXDB_ORG=ut
INFLUXDB_BUCKET=home_assistant
INFLUXDB_USER=anji5h
INFLUXDB_PASSWORD=T@rtu8090
SIMULATOR_FREQUENCY=100
EOF

echo ">>> Starting application with Docker Compose..."
docker compose up -d --build

echo "=================================================="
echo "Deployment Complete!"
echo "=================================================="