#!/bin/bash
# Installs the custom sdmon Prometheus exporter (script + systemd timer).
# Requires node_exporter and sdmon to already be installed.
# Can be run standalone or called from a cluster setup script.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$(cd "$SCRIPT_DIR/../assets" && pwd)"
BIN_DIR="/usr/local/bin"

echo "Installing custom sdmon exporter..."
sudo cp "$ASSETS_DIR/sdmon_exporter/sdmon_exporter.sh" "$BIN_DIR/sdmon_exporter.sh"
sudo chmod +x "$BIN_DIR/sdmon_exporter.sh"
sudo cp "$ASSETS_DIR/sdmon_exporter/sdmon_exporter.service" /etc/systemd/system/sdmon_exporter.service
sudo cp "$ASSETS_DIR/sdmon_exporter/sdmon_exporter.timer" /etc/systemd/system/sdmon_exporter.timer
sudo systemctl daemon-reload
sudo systemctl enable --now sdmon_exporter.timer

if systemctl is-active --quiet sdmon_exporter.timer; then
  echo "sdmon_exporter.timer is RUNNING."
else
  echo "sdmon_exporter.timer failed to start. Check: sudo journalctl -u sdmon_exporter.service" >&2
  exit 1
fi
