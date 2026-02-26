#!/bin/bash
set -e

FIO_DIR=/home/pi/fio
FIO_JOB="$FIO_DIR/config.fio"
SLEEP_INTERVAL=15

while true; do
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  OUTPUT_FILE="$FIO_DIR/fio_$TIMESTAMP.json"
  echo "Starting endurance cycle..."
  fio "$FIO_JOB" --output="$OUTPUT_FILE" --output-format=json
  echo "Endurance cycle completed."
  sleep $SLEEP_INTERVAL
done
