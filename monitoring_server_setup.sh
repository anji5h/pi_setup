#!/bin/bash
# Monitoring server setup: Docker + Prometheus + Grafana + cAdvisor.
# Run on the central server that scrapes metrics from the Pi clusters.
# Run as a regular user with sudo privileges (not as root): ./monitoring_server_setup.sh
#
# Required: GRAFANA_ADMIN_PASSWORD must be set in the environment, e.g.
#   GRAFANA_ADMIN_PASSWORD='yourpassword' ./monitoring_server_setup.sh
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/pi-monitoring}"
GRAFANA_ADMIN_USER="${GRAFANA_ADMIN_USER:-admin}"
GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:?Set GRAFANA_ADMIN_PASSWORD, e.g. GRAFANA_ADMIN_PASSWORD='...' ./monitoring_server_setup.sh}"
PROM_RETENTION="${PROM_RETENTION:-180d}"

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    echo "Docker already installed. Skipping."
    return
  fi

  echo "Installing Docker..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update

  sudo mkdir -p /etc/docker
  echo '{
  "default-address-pools": [{ "base": "172.80.0.0/16", "size": 24 }]
}' | sudo tee /etc/docker/daemon.json > /dev/null

  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER"
  echo "Docker installed. Log out/in (or reboot) for docker-group membership to take effect."
}

write_configs() {
  mkdir -p "$INSTALL_DIR/prometheus"

  cat > "$INSTALL_DIR/docker-compose.yml" <<EOF
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=${PROM_RETENTION}'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    volumes:
      - ./prometheus/prometheus.yaml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_ADMIN_USER}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - monitoring

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    ports:
      - "8080:8080"
    restart: unless-stopped
    networks:
      - monitoring

volumes:
  prometheus_data:
    driver: local
  grafana_data:
    driver: local

networks:
  monitoring:
    driver: bridge
EOF

  # Edit the target IPs below if the cluster's node_exporter addresses change.
  cat > "$INSTALL_DIR/prometheus/prometheus.yaml" <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  # Ultra SD card group (5 nodes, node_exporter only)
  - job_name: 'rpi_ultra'
    static_configs:
      - targets:
          - '172.17.141.100:9100'   # pi-ultra-1
          - '172.17.142.232:9100'   # pi-ultra-2
          - '172.17.142.234:9100'   # pi-ultra-3
          - '172.17.142.233:9100'   # pi-ultra-4
          - '172.17.143.146:9100'   # pi-ultra-5
        labels:
          sd_card_type: 'ultra'
          group: 'rpi_cluster'

  # High Endurance SD card group (5 nodes, node_exporter + sdmon)
  - job_name: 'rpi_high_endurance'
    static_configs:
      - targets:
          - '172.17.143.51:9100'    # pi-hend-1
          - '172.17.143.99:9100'    # pi-hend-2
          - '172.17.141.106:9100'   # pi-hend-3
          - '172.17.141.99:9100'    # pi-hend-4
          - '172.17.141.107:9100'   # pi-hend-5
        labels:
          sd_card_type: 'high_endurance'
          group: 'rpi_cluster'

  # Industrial SD card group (5 nodes, node_exporter + sdmon)
  - job_name: 'rpi_industrial'
    static_configs:
      - targets:
          - '172.17.143.197:9100'   # pi-ind-1
          - '172.17.141.98:9100'    # pi-ind-2
          - '172.17.142.47:9100'    # pi-ind-3
          - '172.17.141.201:9100'   # pi-ind-4
          - '172.17.142.142:9100'   # pi-ind-5
        labels:
          sd_card_type: 'industrial'
          group: 'rpi_cluster'

  # Thermal camera temperature metrics
  - job_name: 'thermal_camera'
    static_configs:
      - targets:
          - '172.17.142.143:8000'
        labels:
          group: 'thermal_monitor'
EOF
}

install_docker
write_configs

echo "Starting monitoring stack..."
cd "$INSTALL_DIR"
docker compose up -d

echo "--- Monitoring stack is up ---"
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "Prometheus: http://${IP_ADDR}:9090"
echo "Grafana:    http://${IP_ADDR}:3000  (user: ${GRAFANA_ADMIN_USER})"
echo "cAdvisor:   http://${IP_ADDR}:8080"
