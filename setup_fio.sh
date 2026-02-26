#!/usr/bin/env bash
set -Eeuo pipefail

FIO_DIR="/home/pi/fio"
TEST_DIR="${FIO_DIR}/test"
FIO_JOB="${FIO_DIR}/config.fio"
SERVICE_NAME="fio.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

log() {
    echo "[INFO] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

if [[ "$EUID" -ne 0 ]]; then
    error "Run this script as root: sudo $0"
fi

[[ -f "./fio/fio.sh" ]] || error "Missing ./fio/fio.sh"
[[ -f "./fio/fio.service" ]] || error "Missing ./fio/fio.service"

log "Creating directories..."
install -d -m 755 "$FIO_DIR"
install -d -m 755 "$TEST_DIR"

log "Installing service and script..."
install -m 755 ./fio/fio.sh "$FIO_DIR/fio.sh"
install -m 644 ./fio/fio.service "$SERVICE_PATH"

if ! command -v fio >/dev/null 2>&1; then
    log "Installing fio..."
    apt-get update -y
    apt-get install -y fio
else
    log "fio already installed."
fi

log "Creating FIO job file at $FIO_JOB..."

cat > "$FIO_JOB" <<EOF
[global]
directory=$TEST_DIR
ioengine=libaio
direct=1
time_based=1
runtime=3600
group_reporting=1
fsync=1
randrepeat=0

[log_writer]
rw=write
bs=4k
size=512m
filesize=50m
nrfiles=10
create_on_open=1
unlink=1
iodepth=1

[temp_files]
rw=randwrite
bs=4k
size=1g
filesize=1m
nrfiles=200
create_on_open=1
unlink=1
iodepth=4

[metadata_stress]
rw=write
bs=1k
size=200m
filesize=4k
nrfiles=1000
create_on_open=1
unlink=1
iodepth=1

[random_db]
rw=randrw
rwmixread=30
bs=4k
size=512m
filesize=100m
nrfiles=5
create_on_open=1
unlink=0
iodepth=4
EOF

chmod 644 "$FIO_JOB"

log "Reloading systemd..."
systemctl daemon-reload

log "Validating service..."
systemd-analyze verify "$SERVICE_PATH" || error "Service validation failed"

log "Enabling service..."
systemctl enable "$SERVICE_NAME"

log "Restarting service..."
systemctl restart "$SERVICE_NAME"

log "Setup completed successfully."