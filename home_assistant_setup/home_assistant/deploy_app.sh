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

echo ">>> Performing complete Docker cleanup before deployment..."
docker compose down -v --remove-orphans 2>/dev/null || true

echo ">>> Making init.sh executable..."
chmod +x init.sh

echo ">>> Generating a strong random password for PostgreSQL (10 characters)..."
POSTGRES_PASSWORD=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 10)

echo ""
echo "Please specify the following configuration values (press Enter to use default):"
echo ""

# Workload type
read -p "Workload type [HIGH]: " WORKLOAD
WORKLOAD=$(echo "${WORKLOAD:-HIGH}" | tr '[:lower:]' '[:upper:]')

# Write / Read intervals
read -p "Write interval (seconds) [3]: " WRITE_INTERVAL
WRITE_INTERVAL="${WRITE_INTERVAL:-3}"

read -p "Read interval (seconds) [6]: " READ_INTERVAL
READ_INTERVAL="${READ_INTERVAL:-6}"

# TimescaleDB retention & compression
read -p "TimescaleDB retention period (hours) [24]: " TIMESCALE_RETENTION_HOURS
TIMESCALE_RETENTION_HOURS="${TIMESCALE_RETENTION_HOURS:-24}"

read -p "TimescaleDB compression after (hours) [6]: " TIMESCALE_COMPRESSION_HOURS
TIMESCALE_COMPRESSION_HOURS="${TIMESCALE_COMPRESSION_HOURS:-6}"

echo ""
echo ">>> Creating .env file with your settings..."
cat <<EOF > .env
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DATABASE=home_assistant
POSTGRES_USER=postgres
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
WORKLOAD=${WORKLOAD}
WRITE_INTERVAL=${WRITE_INTERVAL}
READ_INTERVAL=${READ_INTERVAL}
TIMESCALE_RETENTION_HOURS=${TIMESCALE_RETENTION_HOURS}
TIMESCALE_COMPRESSION_HOURS=${TIMESCALE_COMPRESSION_HOURS}
EOF

echo ">>> .env file created successfully."
echo ""
echo ">>> Starting application with Docker Compose..."
docker compose up -d --build

echo "=================================================="
echo "Deployment Complete!"
echo ""
echo "IMPORTANT: Your PostgreSQL password is:"
echo "  ${POSTGRES_PASSWORD}"
echo ""
echo "Save it somewhere safe if you need to access PostgreSQL directly"
echo "(via psql, UI, or any client). It is only shown now!"
echo ""
echo "Used configuration:"
echo "  Workload              : ${WORKLOAD}"
echo "  Write interval        : ${WRITE_INTERVAL} seconds"
echo "  Read interval         : ${READ_INTERVAL} seconds"
echo "  Retention period      : ${TIMESCALE_RETENTION_HOURS} hours"
echo "  Compression after     : ${TIMESCALE_COMPRESSION_HOURS} hours"
echo "=================================================="