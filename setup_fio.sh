#!/usr/bin/env bash
# vim: ft=bash ts=4 sw=4 sts=4 et

set -euo pipefail
# set -x   # uncomment during debugging

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FIO_BASE_DIR="/home/pi/fio"
readonly TEST_DIR="${FIO_BASE_DIR}/test"
readonly FIO_JOB_FILE="${FIO_BASE_DIR}/config.fio"
readonly SERVICE_NAME="fio.service"
readonly SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"

# ─── Helpers ────────────────────────────────────────────────────────────────

die() {
    echo "[ERROR] $*" >&2
    exit 1
}

log() {
    echo "[INFO]  $*"
}

require_root() {
    (( EUID == 0 )) || die "This script must be run as root (sudo)"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

file_exists() {
    [[ -f "$1" ]]
}

# ─── Main logic ─────────────────────────────────────────────────────────────

require_root

# Source files must exist **relative to script location**
for file in "fio.sh" "fio.service"; do
    if ! file_exists "${SCRIPT_DIR}/fio/${file}"; then
        die "Required file not found: ${SCRIPT_DIR}/fio/${file}"
    fi
done

log "Creating directories (755) …"
install -d -m 0755 "${FIO_BASE_DIR}" "${TEST_DIR}" || die "Cannot create directories"

log "Installing script and service file …"
install -m 0755 "${SCRIPT_DIR}/fio/fio.sh"    "${FIO_BASE_DIR}/fio.sh"
install -m 0644 "${SCRIPT_DIR}/fio/fio.service" "${SERVICE_FILE}"

# ─── Install fio if missing ─────────────────────────────────────────────────
if ! command_exists fio; then
    log "Installing fio package …"
    # ── non-interactive, no recommends/suggests to keep image lean ───────
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq ||
        die "apt-get update failed"

    apt-get install -y --no-install-recommends fio ||
        die "fio installation failed"
else
    log "fio is already installed."
fi

# ─── Write job file ─────────────────────────────────────────────────────────
log "Creating FIO job file → ${FIO_JOB_FILE}"

cat > "${FIO_JOB_FILE}" << 'EOF'
[global]
directory=${TEST_DIR}
ioengine=libaio
direct=1
time_based=1
runtime=3600
group_reporting=1
fsync=1
randrepeat=0
iodepth_batch_submit=32
iodepth_batch_complete_min=1

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

chmod 0644 "${FIO_JOB_FILE}" || die "Cannot chmod job file"

# ─── Systemd ────────────────────────────────────────────────────────────────
log "Reloading systemd daemon …"
systemctl daemon-reload || die "daemon-reload failed"

log "Verifying service file syntax …"
if ! systemd-analyze verify "${SERVICE_FILE}" >/dev/null 2>&1; then
    echo "Service file validation failed. Content follows:" >&2
    cat "${SERVICE_FILE}" >&2
    die "Invalid service file"
fi

log "Enabling and (re)starting service …"
systemctl enable --now --quiet "${SERVICE_NAME}" || die "Failed to enable/start ${SERVICE_NAME}"

# Optional: show quick status
log "Setup appears successful. Current service status:"
systemctl --no-pager status "${SERVICE_NAME}" | head -n 12

exit 0