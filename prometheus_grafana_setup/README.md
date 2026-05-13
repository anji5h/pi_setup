# Prometheus & Grafana Setup

This folder contains Docker Compose configuration for running Prometheus and Grafana with cAdvisor for monitoring Raspberry Pi clusters and container metrics.

## Overview

This setup provides:
- **Prometheus**: Time-series database for storing metrics
- **Grafana**: Data visualization and dashboarding platform
- **cAdvisor**: Container metrics collection

The services collect metrics from Node Exporter instances across multiple Raspberry Pi nodes and expose them through Grafana dashboards.

## Prerequisites

- Raspberry Pi with Docker and Docker Compose installed (see `../docker_setup/`)
- Internet connection
- Sufficient disk space for metrics storage (150+ GB recommended for 6 months retention)
- Optional: Node Exporter running on monitored Pi instances (see `../node_exporter_setup/`)

## Folder Structure

```
prometheus_grafana_setup/
├── docker-compose.yml          # Docker Compose configuration
├── prometheus/                 # Prometheus configuration
│   ├── prometheus.yaml         # Scrape configs for data collection
│   └── (other prometheus files)
├── grafana/                    # Grafana configuration (optional)
│   └── provisioning/
└── README.md
```

## Installation & Startup

### Step 1: Navigate to the folder

```bash
cd prometheus_grafana_setup
```

### Step 2: Start the services

```bash
docker compose up -d
```

This will:
- Pull latest images for Prometheus, Grafana, and cAdvisor
- Create volumes for persistent data storage
- Create a Docker network for container communication
- Start all services in the background

### Step 3: Verify services are running

```bash
docker compose ps
```

All services should show "Up" status.

## Verification

### Prometheus

```bash
# Access Prometheus web UI
# http://<pi_ip>:9090

# Check targets status
# http://<pi_ip>:9090/targets
```

### Grafana

```bash
# Access Grafana
# http://<pi_ip>:3000

# Default credentials
# Username: anjish
# Password: T@rtu879 (configured in docker-compose.yml)
```

### cAdvisor

```bash
# Access cAdvisor
# http://<pi_ip>:8080
```

## Configuration

### Prometheus Configuration

Edit `prometheus/prometheus.yaml` to add or modify scrape targets:

```yaml
scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['<pi_ip>:9100']
```

**Important**: After editing the config, restart Prometheus:

```bash
docker compose restart prometheus
```

### Data Retention

The default retention is set to **180 days** (6 months). To modify:

Edit `docker-compose.yml` and change:

```yaml
command:
  - '--storage.tsdb.retention.time=180d'  # Change to desired duration
```

Then restart: `docker compose restart prometheus`

Supported formats: `300s`, `1h`, `1d`, `180d`, etc.

### Grafana Credentials

Change admin password in `docker-compose.yml`:

```yaml
environment:
  - GF_SECURITY_ADMIN_USER=anjish
  - GF_SECURITY_ADMIN_PASSWORD=your_new_password  # Change this
```

Then restart: `docker compose restart grafana`

## Service Management

### View logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f prometheus
docker compose logs -f grafana
docker compose logs -f cadvisor
```

### Stop services

```bash
docker compose down
```

### Restart services

```bash
docker compose restart
```

### Update to latest images

```bash
docker compose pull
docker compose up -d
```

### View disk usage

```bash
# Check Prometheus data volume size
docker system df

# Size of Prometheus storage
du -sh prometheus_data/
```

## Monitoring Targets

The current configuration monitors multiple Raspberry Pi node groups:

### Configured Groups

1. **rpi_ultra** - 5 nodes with Ultra SD cards
2. **rpi_high_endurance** - 5 nodes with High Endurance SD cards
3. **rpi_industrial** - 5 nodes with Industrial SD cards
4. **thermal_camera** - Thermal monitoring node
5. **cadvisor** - Local container metrics

Each group is configured with:
- Individual target IPs and ports
- Custom labels for grouping and filtering
- 15-second scrape interval

### Adding New Targets

Edit `prometheus/prometheus.yaml` and add new job:

```yaml
- job_name: 'my_new_device'
  static_configs:
    - targets: ['192.168.1.100:9100']
      labels:
        device_name: 'my-device'
        group: 'my_group'
```

Then restart Prometheus: `docker compose restart prometheus`

## Network Configuration

All services communicate through a Docker bridge network named `monitoring`. 

To connect external services to this network, use:

```yaml
networks:
  - monitoring
```

## Troubleshooting

### Prometheus not accessible

```bash
# Check if container is running
docker compose ps prometheus

# Check logs
docker compose logs prometheus

# Check port binding
docker port prometheus
```

### Grafana won't start

```bash
# Check logs
docker compose logs grafana

# Check disk space
df -h

# Check volume permissions
ls -la grafana_data/
```

### "No targets" in Prometheus

- Verify target IPs are reachable: `ping <target_ip>`
- Verify Node Exporter is running on targets: `curl http://<target_ip>:9100/metrics`
- Check Prometheus logs: `docker compose logs prometheus`

### Out of disk space

```bash
# Check disk usage
du -sh prometheus_data/

# Reduce retention period
# Edit docker-compose.yml and restart
docker compose restart prometheus

# Or clean up old data
docker system prune -a
```

### High memory usage

- Reduce scrape frequency in `prometheus.yaml`
- Reduce retention period
- Remove unnecessary scrape jobs

## Performance Tips

- Adjust scrape interval in `prometheus.yaml` (default 15s)
- Use target filtering to reduce data points
- Enable compression in Prometheus if needed
- Regular backups of `prometheus_data` volume

## Backup & Recovery

### Backup Prometheus data

```bash
docker compose stop prometheus
cp -r prometheus_data prometheus_data.backup
docker compose start prometheus
```

### Backup Grafana data

```bash
docker compose stop grafana
cp -r grafana_data grafana_data.backup
docker compose start grafana
```

## Next Steps

1. Configure monitoring targets in `prometheus/prometheus.yaml`
2. Access Grafana at `http://<pi_ip>:3000`
3. Create dashboards for your monitored nodes
4. Setup alerts based on metrics

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [cAdvisor Documentation](https://github.com/google/cadvisor)
- [Docker Compose Docs](https://docs.docker.com/compose/)
