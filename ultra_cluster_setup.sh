#!/bin/bash
# Ultra cluster setup: installs Prometheus Node Exporter.
# Run as a regular user with sudo privileges (not as root): ./ultra_cluster_setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"

NODE_EXPORTER_VERSION="${NODE_EXPORTER_VERSION:-1.12.1}"
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

install_node_exporter

if systemctl is-active --quiet node_exporter; then
  echo "node_exporter is RUNNING. Metrics: http://$(hostname -I | awk '{print $1}'):9100/metrics"
else
  echo "node_exporter failed to start. Check: sudo journalctl -u node_exporter" >&2
  exit 1
fi
