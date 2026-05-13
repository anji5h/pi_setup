#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- Configuration ---
# Check https://github.com/prometheus/node_exporter/releases for the latest version
VERSION="1.10.2"
ARCH="armv7" # Use 'arm64' if you are using a 64-bit Raspberry Pi OS
USER="nobody"
BIN_DIR="/usr/local/bin"
TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"

# 4. Ensure Textfile Collector Directory Exists
if [ ! -d "$TEXTFILE_DIR" ]; then
    echo "Creating metrics directory: $TEXTFILE_DIR"
    sudo mkdir -p "$TEXTFILE_DIR"
    sudo chown nobody:nogroup "$TEXTFILE_DIR"
fi

echo "--- Starting Node Exporter Installation ($VERSION-$ARCH) ---"

# 1. Download Node Exporter
echo "Downloading Node Exporter..."
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-${ARCH}.tar.gz

# 2. Extract the tarball
echo "Extracting files..."
tar xvfz node_exporter-${VERSION}.linux-${ARCH}.tar.gz

# 3. Move binary to /usr/local/bin
echo "Moving binary to ${BIN_DIR}..."
sudo mv node_exporter-${VERSION}.linux-${ARCH}/node_exporter ${BIN_DIR}/

# 4. Create systemd service
echo "Creating systemd service file..."
sudo tee /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
ExecStart=${BIN_DIR}/node_exporter --collector.textfile.directory=${TEXTFILE_DIR}
User=${USER}
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 5. Enable and start the service
echo "Enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# 6. Cleanup
echo "Cleaning up temporary files..."
rm node_exporter-${VERSION}.linux-${ARCH}.tar.gz
rm -rf node_exporter-${VERSION}.linux-${ARCH}

# 7. Verification
echo "--- Installation Complete ---"
# Check status
if systemctl is-active --quiet node_exporter; then
    echo "Service is RUNNING."
else
    echo "Service failed to start. Check 'sudo journalctl -u node_exporter'."
fi

# Get the Pi's IP address
IP_ADDR=$(hostname -I | awk '{print $1}')
echo ""
echo "You can verify metrics at:"
echo "http://${IP_ADDR}:9100/metrics"
