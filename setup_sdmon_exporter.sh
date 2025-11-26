#!/bin/bash
set -e

echo "--- Deploying sdmon Exporter Files ---"

# 1. Move the Script and make executable
if [ -f "sdmon_exporter/sdmon_exporter.sh" ]; then
    echo "Installing script to /usr/local/bin/..."
    sudo mv sdmon_exporter/sdmon_exporter.sh /usr/local/bin/
    sudo chmod +x /usr/local/bin/sdmon_exporter.sh
else
    echo "Error: 'sdmon_exporter.sh' not found in current directory."
    exit 1
fi

# 2. Move Systemd Service
if [ -f "sdmon_exporter/sdmon_exporter.service" ]; then
    echo "Installing service file..."
    sudo mv sdmon_exporter/sdmon_exporter.service /etc/systemd/system/
else
    echo "Error: 'sdmon_exporter.service' not found in current directory."
    exit 1
fi

# 3. Move Systemd Timer
if [ -f "sdmon_exporter/sdmon_exporter.timer" ]; then
    echo "Installing timer file..."
    sudo mv sdmon_exporter/sdmon_exporter.timer /etc/systemd/system/
else
    echo "Error: 'sdmon_exporter.timer' not found in current directory."
    exit 1
fi

# 5. Enable and Start
echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Enabling and starting timer..."
sudo systemctl enable --now sdmon_exporter.timer

if systemctl is-active --quiet sdmon_exporter.timer; then
    echo "sdmon_exporter.timer is active and running."
else
    echo "Error: sdmon_exporter.timer failed to start."
    exit 1
fi

echo "--- sdmon Exporter setup complete ---"