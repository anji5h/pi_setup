# SDMON Setup

This folder contains the installation script and configuration for SDMON (Storage Device Monitor) and its Prometheus exporter on Raspberry Pi.

## Overview

SDMON is a tool that monitors SD card health and metrics on Raspberry Pi. It provides:
- SD card temperature monitoring
- Write/read performance metrics
- SMART-like data collection

The sdmon exporter runs as a systemd timer service and exposes metrics in Prometheus format for collection by Node Exporter's textfile collector.

## Prerequisites

- Raspberry Pi running Debian-based OS (Raspberry Pi OS)
- Node Exporter already installed (see `../node_exporter_setup/`)
- Internet connection
- SSH access or terminal access to the Pi
- `sudo` privileges
- `jq` (JSON query tool - installed by the script)

## Architecture Support

- **ARMv7 (32-bit)**: Raspberry Pi 2, 3, 3B+, 4, 5 running 32-bit OS
- **ARM64 (64-bit)**: Edit `install.sh` and change `sdmon-armv7.tar.gz` to `sdmon-arm64.tar.gz`

## Folder Structure

```
sdmon_setup/
├── install.sh              # Installs sdmon binary
├── setup_exporter.sh       # Configures sdmon exporter service
├── sdmon_exporter/         # Custom collector files
│   ├── sdmon_exporter.sh           # Exporter script
│   ├── sdmon_exporter.service      # Systemd service
│   └── sdmon_exporter.timer        # Systemd timer
└── README.md
```

## Installation

### Step 1: Install sdmon Binary

```bash
cd sdmon_setup
chmod +x install.sh
sudo ./install.sh
```

This script will:
- Install `jq` (JSON parser)
- Download sdmon v0.9.0 for ARMv7
- Extract and install to `/usr/local/bin/`
- Verify installation

### Step 2: Setup Exporter Service

```bash
chmod +x setup_exporter.sh
sudo ./setup_exporter.sh
```

This script will:
- Copy the exporter script to `/usr/local/bin/`
- Install systemd service and timer
- Enable and start the timer
- Verify everything is running

## Verification

After installation, verify sdmon is working:

```bash
# Check sdmon command exists
which sdmon

# Run sdmon manually (optional test)
sudo sdmon /dev/mmcblk0

# Check exporter service status
sudo systemctl status sdmon_exporter.timer

# View exporter logs
sudo journalctl -u sdmon_exporter.service -f

# Check if metrics are being written
ls -la /var/lib/node_exporter/textfile_collector/
```

You should see `sdmon_*.prom` files in the textfile collector directory.

## How It Works

1. **sdmon** runs the binary and collects SD card metrics
2. **sdmon_exporter.sh** (custom collector) processes sdmon output and converts to Prometheus format
3. **sdmon_exporter.timer** runs the exporter script periodically (configurable)
4. **Node Exporter** textfile collector picks up the `.prom` files
5. **Prometheus** scrapes Node Exporter and gets the sdmon metrics

## Configuration

### Update Exporter Schedule

Edit the timer file to change how often metrics are collected:

```bash
sudo nano /etc/systemd/system/sdmon_exporter.timer
```

Default: Runs every 1 minute

### Change SD Card Device

If you're monitoring a different device, edit the exporter script:

```bash
sudo nano /usr/local/bin/sdmon_exporter.sh
```

Look for the line with `/dev/mmcblk0` and change as needed.

## Service Management

```bash
# Start the timer
sudo systemctl start sdmon_exporter.timer

# Stop the timer
sudo systemctl stop sdmon_exporter.timer

# Enable auto-start
sudo systemctl enable sdmon_exporter.timer

# Disable auto-start
sudo systemctl disable sdmon_exporter.timer

# Check status
sudo systemctl status sdmon_exporter.timer

# View timer information
sudo systemctl status sdmon_exporter.service
```

## Troubleshooting

### Service won't start
```bash
# Check logs
sudo journalctl -u sdmon_exporter.service -n 20

# Check service file syntax
sudo systemd-analyze verify sdmon_exporter.service
```

### sdmon binary not found
```bash
# Verify binary exists
ls -la /usr/local/bin/sdmon

# Re-run installation
cd sdmon_setup
sudo ./install.sh
```

### Metrics not appearing
- Check `/var/lib/node_exporter/textfile_collector/` for `.prom` files
- Verify timer is active: `sudo systemctl status sdmon_exporter.timer`
- Check permissions on textfile directory: `ls -la /var/lib/node_exporter/textfile_collector/`

### Permission denied errors
- Exporter script should run with sudo privileges
- Check if `sdmon_exporter.service` has `User=root`
- Check script permissions: `ls -la /usr/local/bin/sdmon_exporter.sh`

## Metrics Provided

SDMON exposes metrics like:
- SD card temperature
- Device health status
- Operational hours
- Write/read performance indicators

Metrics are exposed as `sdmon_*` in Prometheus format.

## Integration with Prometheus

Once configured, Prometheus automatically collects these metrics from Node Exporter. No additional configuration needed - the textfile collector automatically picks them up.

## References

- [SDMON GitHub](https://github.com/Ognian/sdmon)
- [Node Exporter Textfile Collector](https://github.com/prometheus/node_exporter#textfile-collector)
- [Prometheus Monitoring](https://prometheus.io/docs/)
