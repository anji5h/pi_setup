#!/bin/bash
set -e

FIO_DIR=/home/pi/fio
FIO_JOB="$FIO_DIR/config.fio"
FIO_LOG_DIR="$FIO_DIR/logs"
SLEEP_INTERVAL=600

mkdir -p "$FIO_LOG_DIR"

while true; do
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  OUTPUT_FILE="$FIO_LOG_DIR/fio_$TIMESTAMP.json"
  echo "Starting endurance cycle..."
  fio "$FIO_JOB" --output="$OUTPUT_FILE" --output-format=json
  echo "Endurance cycle completed."
  sleep $SLEEP_INTERVAL
done
