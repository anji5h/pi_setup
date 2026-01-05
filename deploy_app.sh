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

echo ">>> Generating a strong random InfluxDB token..."
INFLUXDB_TOKEN=$(head /dev/urandom | tr -dc 'A-Za-z0-9!@#$%^&*()_+-=[]{}|;:,.<>?' | head -c 32)

echo ">>> Creating .env file..."
cat <<EOF > .env
INFLUXDB_HOST=influxdb
INFLUXDB_PORT=8086
INFLUXDB_TOKEN=$INFLUXDB_TOKEN
INFLUXDB_ORG=ut
INFLUXDB_BUCKET=home_assistant
INFLUXDB_RETENTION=72h
INFLUXDB_USER=anji5h
INFLUXDB_PASSWORD=T@rtu8090
SIMULATOR_FREQUENCY=500
INFLUX_WRITE_INTERVAL=5
INFLUX_READ_INTERVAL=7
EOF

echo ">>> .env file created successfully."

echo ">>> Starting application with Docker Compose..."
docker compose up -d --build

echo "=================================================="
echo "Deployment Complete!"
echo ""
echo "IMPORTANT: Your InfluxDB token is:"
echo "    $INFLUXDB_TOKEN"
echo ""
echo "Save it somewhere safe if you need to access InfluxDB directly"
echo "(e.g., via CLI, UI, or API). It is only shown now and stored in .env."
echo "=================================================="