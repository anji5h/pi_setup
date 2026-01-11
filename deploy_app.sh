#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

REPO_URL="https://github.com/anji5h/home_assistant.git"
DIR_NAME="/home/pi/home_assistant"

echo ">>> Cloning repository..."
if [ -d "$DIR_NAME" ]; then
    echo "Directory '$DIR_NAME' already exists. Skipping clone."
else
    git clone "$REPO_URL" "$DIR_NAME"
fi

echo ">>> Navigating into directory..."
cd "$DIR_NAME"

echo ">>> Making init.sh executable..."
chmod +x init.sh

echo ">>> Generating a strong random InfluxDB token..."
INFLUXDB_TOKEN=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)

echo ""
echo "Please specify the following configuration values (press Enter to use default):"
echo ""

# InfluxDB retention period
read -p "InfluxDB retention period (hours) [72]: " INFLUXDB_RETENTION
INFLUXDB_RETENTION="${INFLUXDB_RETENTION:-72}h"

# Simulator settings
read -p "Simulator: points per batch [65]: " SIMULATOR_POINTS_PER_BATCH
SIMULATOR_POINTS_PER_BATCH=${SIMULATOR_POINTS_PER_BATCH:-65}

read -p "Simulator: batch size [5]: " SIMULATOR_BATCH_SIZE
SIMULATOR_BATCH_SIZE=${SIMULATOR_BATCH_SIZE:-5}

# InfluxDB write/read intervals
read -p "InfluxDB write interval (seconds) [5]: " INFLUX_WRITE_INTERVAL
INFLUX_WRITE_INTERVAL=${INFLUX_WRITE_INTERVAL:-5}

read -p "InfluxDB read interval (seconds) [20]: " INFLUX_READ_INTERVAL
INFLUX_READ_INTERVAL=${INFLUX_READ_INTERVAL:-20}

echo ""
echo ">>> Creating .env file with your settings..."
cat <<EOF > .env
INFLUXDB_HOST=influxdb
INFLUXDB_PORT=8086
INFLUXDB_TOKEN=$INFLUXDB_TOKEN
INFLUXDB_ORG=ut
INFLUXDB_BUCKET=home_assistant
INFLUXDB_RETENTION=$INFLUXDB_RETENTION
INFLUXDB_USER=anji5h
INFLUXDB_PASSWORD=T@rtu8090
SIMULATOR_POINTS_PER_BATCH=$SIMULATOR_POINTS_PER_BATCH
SIMULATOR_BATCH_SIZE=$SIMULATOR_BATCH_SIZE
INFLUX_WRITE_INTERVAL=$INFLUX_WRITE_INTERVAL
INFLUX_READ_INTERVAL=$INFLUX_READ_INTERVAL
EOF

echo ">>> .env file created successfully."
echo ""
echo ">>> Starting application with Docker Compose..."
docker compose up -d --build

echo "=================================================="
echo "Deployment Complete!"
echo ""
echo "IMPORTANT: Your InfluxDB token is:"
echo "  $INFLUXDB_TOKEN"
echo ""
echo "Save it somewhere safe if you need to access InfluxDB directly"
echo "(via CLI, UI, or API). It is only shown now and stored in .env."
echo ""
echo "Used configuration:"
echo "  Retention period     : $INFLUXDB_RETENTION"
echo "  Points per batch     : $SIMULATOR_POINTS_PER_BATCH"
echo "  Batch size          : $SIMULATOR_BATCH_SIZE s"
echo "  Influx write interval: $INFLUX_WRITE_INTERVAL s"
echo "  Influx read interval : $INFLUX_READ_INTERVAL s"
echo "=================================================="