# Node Exporter Setup

This folder contains the installation script for Prometheus Node Exporter on Raspberry Pi.

## Overview

Node Exporter is a Prometheus exporter for hardware and OS metrics exposed by the kernel. It collects system metrics like CPU, memory, disk, network statistics, and more.

## Prerequisites

- Raspberry Pi running Debian-based OS (Raspberry Pi OS)
- Internet connection
- SSH access or terminal access to the Pi
- `sudo` privileges

## Architecture Support

- **ARMv7 (32-bit)**: Raspberry Pi 2, 3, 3B+, 4, 5 running 32-bit OS
- **ARM64 (64-bit)**: Raspberry Pi 3, 4, 5 running 64-bit OS

Edit the `ARCH` variable in `install.sh` if you're using 64-bit OS.

## Installation

### Quick Start

```bash
cd node_exporter_setup
chmod +x install.sh
sudo ./install.sh
```

### Manual Steps

1. Navigate to this folder
2. Make the script executable: `chmod +x install.sh`
3. Run with sudo: `sudo ./install.sh`

The script will:
- Download Node Exporter v1.10.2 (or specified version)
- Extract and install the binary to `/usr/local/bin/`
- Create a systemd service for automatic startup
- Enable and start the service
- Verify the installation

## Verification

After installation, verify Node Exporter is running:

```bash
# Check service status
sudo systemctl status node_exporter

# Check metrics are being exported (replace <IP> with your Pi's IP)
curl http://<IP>:9100/metrics
```

You should see Prometheus format metrics output.

## Configuration

### Configurable Variables (in `install.sh`)

- `VERSION`: Node Exporter version to download
- `ARCH`: CPU architecture (armv7 or arm64)
- `USER`: Service user (default: nobody)
- `BIN_DIR`: Installation directory (default: /usr/local/bin)
- `TEXTFILE_DIR`: Directory for custom metrics (default: /var/lib/node_exporter/textfile_collector)

### Custom Metrics

You can add custom metrics to `/var/lib/node_exporter/textfile_collector/` as `.prom` files. Node Exporter will expose them automatically.

Example custom metric file:
```
# HELP my_custom_metric A custom metric
# TYPE my_custom_metric gauge
my_custom_metric 42
```

## Service Management

```bash
# Start the service
sudo systemctl start node_exporter

# Stop the service
sudo systemctl stop node_exporter

# Restart the service
sudo systemctl restart node_exporter

# Check status
sudo systemctl status node_exporter

# View logs
sudo journalctl -u node_exporter -f
```

## Troubleshooting

### Service won't start
- Check logs: `sudo journalctl -u node_exporter -n 20`
- Verify binary exists: `ls -la /usr/local/bin/node_exporter`
- Check file permissions: `sudo chmod +x /usr/local/bin/node_exporter`

### Metrics not accessible
- Verify the service is running: `sudo systemctl status node_exporter`
- Check your Pi's firewall allows port 9100
- Verify metrics endpoint: `curl http://localhost:9100/metrics`

### High CPU/Memory usage
- This is normal if the system has many processes
- You can disable certain collectors by editing the systemd service

## Port

Node Exporter listens on **port 9100** by default.

## Integration with Prometheus

Configure Prometheus to scrape this exporter by adding to `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['<pi_ip>:9100']
```

## References

- [Node Exporter GitHub](https://github.com/prometheus/node_exporter)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Node Exporter Metrics](https://github.com/prometheus/node_exporter#enabled-by-default)
