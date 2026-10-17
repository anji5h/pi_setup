#!/bin/bash
# Installs/updates Prometheus Node Exporter as a systemd service.
# Can be run standalone or called from a cluster setup script.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$(cd "$SCRIPT_DIR/../assets" && pwd)"

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

install_service_unit() {
  sudo cp "$ASSETS_DIR/node_exporter.service" /etc/systemd/system/node_exporter.service
  sudo systemctl daemon-reload
  sudo systemctl enable --now node_exporter
}

need_install=1
if [ -x "${BIN_DIR}/node_exporter" ]; then
  installed_version=$("${BIN_DIR}/node_exporter" --version 2>&1 | head -1 | awk '{print $3}')
  if [ "$installed_version" = "$NODE_EXPORTER_VERSION" ]; then
    echo "node_exporter ${NODE_EXPORTER_VERSION} already installed. Ensuring service is running..."
    install_service_unit
    need_install=0
  else
    echo "Upgrading node_exporter ${installed_version} -> ${NODE_EXPORTER_VERSION}..."
  fi
else
  echo "Installing node_exporter ${NODE_EXPORTER_VERSION} (${ARCH})..."
fi

if [ "$need_install" = "1" ]; then
  sudo mkdir -p "$TEXTFILE_DIR"
  sudo chown nobody:nogroup "$TEXTFILE_DIR"

  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/node_exporter.tar.gz" \
    "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}.tar.gz"
  tar xzf "$tmp/node_exporter.tar.gz" -C "$tmp"
  sudo systemctl stop node_exporter 2>/dev/null || true
  sudo mv "$tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}/node_exporter" "$BIN_DIR/"
  rm -rf "$tmp"

  install_service_unit
fi

if systemctl is-active --quiet node_exporter; then
  echo "node_exporter is RUNNING. Metrics: http://$(hostname -I | awk '{print $1}'):9100/metrics"
else
  echo "node_exporter failed to start. Check: sudo journalctl -u node_exporter" >&2
  exit 1
fi
