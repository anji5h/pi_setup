#!/bin/bash
# High-endurance / industrial cluster setup: Node Exporter + sdmon + custom
# sdmon Prometheus exporter (SD card health metrics).
# Run as a regular user with sudo privileges (not as root): ./storage_cluster_setup.sh
set -euo pipefail

NODE_EXPORTER_VERSION="${NODE_EXPORTER_VERSION:-1.12.1}"
SDMON_VERSION="${SDMON_VERSION:-0.9.0}"
SD_DEVICE="${SD_DEVICE:-/dev/mmcblk0}"
BIN_DIR="/usr/local/bin"
TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"

detect_arch() {
  case "$(uname -m)" in
    aarch64) echo "arm64" ;;
    armv7l|armv6l) echo "armv7" ;;
    *) echo "ERROR: Unsupported architecture $(uname -m)" >&2; exit 1 ;;
  esac
}
ARCH="${ARCH:-$(detect_arch)}"

install_node_exporter() {
  if [ -x "${BIN_DIR}/node_exporter" ]; then
    local installed_version
    installed_version=$("${BIN_DIR}/node_exporter" --version 2>&1 | head -1 | awk '{print $3}')
    if [ "$installed_version" = "$NODE_EXPORTER_VERSION" ]; then
      echo "node_exporter ${NODE_EXPORTER_VERSION} already installed. Ensuring service is running..."
      sudo systemctl enable --now node_exporter
      return
    fi
    echo "Upgrading node_exporter ${installed_version} -> ${NODE_EXPORTER_VERSION}..."
  else
    echo "Installing node_exporter ${NODE_EXPORTER_VERSION} (${ARCH})..."
  fi

  sudo mkdir -p "$TEXTFILE_DIR"
  sudo chown nobody:nogroup "$TEXTFILE_DIR"

  local tmp
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/node_exporter.tar.gz" \
    "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}.tar.gz"
  tar xzf "$tmp/node_exporter.tar.gz" -C "$tmp"
  sudo systemctl stop node_exporter 2>/dev/null || true
  sudo mv "$tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}/node_exporter" "$BIN_DIR/"
  rm -rf "$tmp"

  sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
ExecStart=${BIN_DIR}/node_exporter --collector.textfile.directory=${TEXTFILE_DIR}
User=nobody
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable --now node_exporter
}

install_sdmon() {
  if command -v sdmon >/dev/null 2>&1; then
    echo "sdmon already installed. Skipping binary install."
    return
  fi

  echo "Installing jq..."
  sudo apt-get update -q
  sudo apt-get install -y jq

  echo "Installing sdmon ${SDMON_VERSION} (${ARCH})..."
  local tmp
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/sdmon.tar.gz" \
    "https://github.com/Ognian/sdmon/releases/download/v${SDMON_VERSION}/sdmon-${ARCH}.tar.gz"
  tar xzf "$tmp/sdmon.tar.gz" -C "$tmp"
  sudo mv "$tmp/sdmon" "$BIN_DIR/"
  sudo chmod +x "$BIN_DIR/sdmon"
  rm -rf "$tmp"
}

install_sdmon_exporter() {
  echo "Installing custom sdmon exporter..."

  sudo tee "$BIN_DIR/sdmon_exporter.sh" > /dev/null <<EOF
#!/bin/bash
OUTPUT="${TEXTFILE_DIR}/sdmon.prom"
DEVICE="${SD_DEVICE}"
SDMON_BIN="${BIN_DIR}/sdmon"
PATH="${BIN_DIR}:/usr/bin:/bin"

if [ ! -x "\$SDMON_BIN" ]; then
  echo "ERROR: sdmon binary not found or not executable at \$SDMON_BIN" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq not found (install with 'sudo apt install jq')" >&2
  exit 1
fi

SDMON_JSON=\$("\$SDMON_BIN" "\$DEVICE" 2>/dev/null)

if [ -z "\$SDMON_JSON" ]; then
  echo "No sdmon output. Is this an industrial SD card?" >&2
  exit 1
fi

GOOD_BLOCK_RATE=\$(echo "\$SDMON_JSON" | jq '.goodBlockRatePercent // 0')
ENDURANCE_LEFT=\$(echo "\$SDMON_JSON" | jq '.enduranceRemainLifePercent // 0')
AVG_ERASE_COUNT=\$(echo "\$SDMON_JSON" | jq '.avgEraseCount // 0')
TOTAL_ERASE_COUNT=\$(echo "\$SDMON_JSON" | jq '.totalEraseCount // 0')
SPARE_BLOCK_COUNT=\$(echo "\$SDMON_JSON" | jq '.spareBlockCount // 0')
INITIAL_BAD_BLOCKS=\$(echo "\$SDMON_JSON" | jq '.initialBadBlockCount // 0')
LATER_BAD_BLOCKS=\$(echo "\$SDMON_JSON" | jq '.laterBadBlockCount // 0')
POWER_UPS=\$(echo "\$SDMON_JSON" | jq '.powerUpCount // 0')

TEMP_FILE="\${OUTPUT}.tmp"
cat <<METRICS > "\$TEMP_FILE"
# HELP sdcard_good_block_rate_percent Good block rate (%)
# TYPE sdcard_good_block_rate_percent gauge
sdcard_good_block_rate_percent \$GOOD_BLOCK_RATE

# HELP sdcard_endurance_remaining_percent Remaining estimated endurance (%)
# TYPE sdcard_endurance_remaining_percent gauge
sdcard_endurance_remaining_percent \$ENDURANCE_LEFT

# HELP sdcard_avg_erase_count Average erase count
# TYPE sdcard_avg_erase_count gauge
sdcard_avg_erase_count \$AVG_ERASE_COUNT

# HELP sdcard_total_erase_count Total erase count
# TYPE sdcard_total_erase_count counter
sdcard_total_erase_count \$TOTAL_ERASE_COUNT

# HELP sdcard_spare_block_count Number of spare blocks remaining
# TYPE sdcard_spare_block_count gauge
sdcard_spare_block_count \$SPARE_BLOCK_COUNT

# HELP sdcard_initial_bad_block_count Number of bad blocks detected at manufacture
# TYPE sdcard_initial_bad_block_count gauge
sdcard_initial_bad_block_count \$INITIAL_BAD_BLOCKS

# HELP sdcard_later_bad_block_count Number of bad blocks detected after manufacture
# TYPE sdcard_later_bad_block_count gauge
sdcard_later_bad_block_count \$LATER_BAD_BLOCKS

# HELP sdcard_powerup_count Total power-up count
# TYPE sdcard_powerup_count counter
sdcard_powerup_count \$POWER_UPS
METRICS

mv "\$TEMP_FILE" "\$OUTPUT"
EOF
  sudo chmod +x "$BIN_DIR/sdmon_exporter.sh"

  sudo tee /etc/systemd/system/sdmon_exporter.service > /dev/null <<EOF
[Unit]
Description=Sdmon Metrics Exporter
After=network.target

[Service]
Type=oneshot
User=root
ExecStart=${BIN_DIR}/sdmon_exporter.sh
Nice=10

[Install]
WantedBy=multi-user.target
EOF

  sudo tee /etc/systemd/system/sdmon_exporter.timer > /dev/null <<EOF
[Unit]
Description=Run sdmon exporter service every minute

[Timer]
OnBootSec=50s
OnUnitActiveSec=50s
AccuracySec=10s
Unit=sdmon_exporter.service

[Install]
WantedBy=timers.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable --now sdmon_exporter.timer
}

install_node_exporter
install_sdmon
install_sdmon_exporter

echo "--- Installation Summary ---"
systemctl is-active --quiet node_exporter && echo "node_exporter:       RUNNING" || echo "node_exporter:       FAILED"
systemctl is-active --quiet sdmon_exporter.timer && echo "sdmon_exporter.timer: RUNNING" || echo "sdmon_exporter.timer: FAILED"
echo "Metrics: http://$(hostname -I | awk '{print $1}'):9100/metrics"
