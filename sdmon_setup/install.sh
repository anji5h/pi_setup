#!/bin/bash
set -e

# Configuration for ARMv7 (32-bit)
SDMON_ARCHIVE="sdmon-armv7.tar.gz"
SDMON_URL="https://github.com/Ognian/sdmon/releases/download/v0.9.0/${SDMON_ARCHIVE}"

echo "--- Installing jq ---"
sudo apt-get update -q
sudo apt-get install -y jq

echo "jq installation complete."

echo "--- Installing sdmon (ARMv7) ---"
cd /tmp
echo "Downloading $SDMON_ARCHIVE..."
curl -LO "$SDMON_URL"

echo "Extracting files..."
tar xvfz "$SDMON_ARCHIVE"

echo "Installing binary to /usr/local/bin..."
sudo mv sdmon /usr/local/bin/
sudo chmod +x /usr/local/bin/sdmon

# Cleanup
rm "$SDMON_ARCHIVE"

echo "--- Installation Complete ---"
echo "You can run it using: sudo sdmon /dev/mmcblk0"
