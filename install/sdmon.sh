#!/bin/bash
# Installs the sdmon binary (SD card health tool) and its jq dependency.
# Can be run standalone or called from a cluster setup script.
set -euo pipefail

SDMON_VERSION="${SDMON_VERSION:-0.9.0}"
BIN_DIR="/usr/local/bin"

detect_arch() {
  case "$(uname -m)" in
    aarch64) echo "arm64" ;;
    armv7l|armv6l) echo "armv7" ;;
    *) echo "ERROR: Unsupported architecture $(uname -m)" >&2; exit 1 ;;
  esac
}
ARCH="${ARCH:-$(detect_arch)}"

if command -v sdmon >/dev/null 2>&1; then
  echo "sdmon already installed. Skipping binary install."
  exit 0
fi

echo "Installing jq..."
sudo apt-get update -q
sudo apt-get install -y jq

echo "Installing sdmon ${SDMON_VERSION} (${ARCH})..."
tmp=$(mktemp -d)
curl -fsSL -o "$tmp/sdmon.tar.gz" \
  "https://github.com/Ognian/sdmon/releases/download/v${SDMON_VERSION}/sdmon-${ARCH}.tar.gz"
tar xzf "$tmp/sdmon.tar.gz" -C "$tmp"
sudo mv "$tmp/sdmon" "$BIN_DIR/"
sudo chmod +x "$BIN_DIR/sdmon"
rm -rf "$tmp"

echo "sdmon installed at ${BIN_DIR}/sdmon. Run it with: sudo sdmon /dev/mmcblk0"
