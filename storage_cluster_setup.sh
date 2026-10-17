#!/bin/bash
# High-endurance / industrial cluster setup: Node Exporter + sdmon + custom
# sdmon Prometheus exporter (SD card health metrics).
# Run as a regular user with sudo privileges (not as root): ./storage_cluster_setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"

NODE_EXPORTER_VERSION="${NODE_EXPORTER_VERSION:-1.12.1}"
SDMON_VERSION="${SDMON_VERSION:-0.9.0}"
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
      sudo cp "$ASSETS_DIR/node_exporter.service" /etc/systemd/system/node_exporter.service
      sudo systemctl daemon-reload
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

  sudo cp "$ASSETS_DIR/node_exporter.service" /etc/systemd/system/node_exporter.service
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
  sudo cp "$ASSETS_DIR/sdmon_exporter/sdmon_exporter.sh" "$BIN_DIR/sdmon_exporter.sh"
  sudo chmod +x "$BIN_DIR/sdmon_exporter.sh"
  sudo cp "$ASSETS_DIR/sdmon_exporter/sdmon_exporter.service" /etc/systemd/system/sdmon_exporter.service
  sudo cp "$ASSETS_DIR/sdmon_exporter/sdmon_exporter.timer" /etc/systemd/system/sdmon_exporter.timer
  sudo systemctl daemon-reload
  sudo systemctl enable --now sdmon_exporter.timer
}

install_node_exporter
install_sdmon
install_sdmon_exporter

echo "--- Installation Summary ---"
systemctl is-active --quiet node_exporter && echo "node_exporter:        RUNNING" || echo "node_exporter:        FAILED"
systemctl is-active --quiet sdmon_exporter.timer && echo "sdmon_exporter.timer: RUNNING" || echo "sdmon_exporter.timer: FAILED"
echo "Metrics: http://$(hostname -I | awk '{print $1}'):9100/metrics"
