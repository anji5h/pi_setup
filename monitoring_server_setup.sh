#!/bin/bash
# Monitoring server setup: Docker + Prometheus + Grafana + cAdvisor.
# Run on the central server that scrapes metrics from the Pi clusters.
# Run as a regular user with sudo privileges (not as root): ./monitoring_server_setup.sh
#
# Required: GRAFANA_ADMIN_PASSWORD must be set in the environment, e.g.
#   GRAFANA_ADMIN_PASSWORD='yourpassword' ./monitoring_server_setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets/monitoring"

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

deploy_stack() {
  mkdir -p "$INSTALL_DIR"
  cp "$ASSETS_DIR/docker-compose.yml" "$INSTALL_DIR/docker-compose.yml"
  cp -r "$ASSETS_DIR/prometheus" "$INSTALL_DIR/"

  cat > "$INSTALL_DIR/.env" <<EOF
GRAFANA_ADMIN_USER=${GRAFANA_ADMIN_USER}
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
PROM_RETENTION=${PROM_RETENTION}
EOF
  chmod 600 "$INSTALL_DIR/.env"
}

install_docker
deploy_stack

echo "Starting monitoring stack..."
cd "$INSTALL_DIR"
docker compose up -d

echo "--- Monitoring stack is up ---"
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "Prometheus: http://${IP_ADDR}:9090"
echo "Grafana:    http://${IP_ADDR}:3000  (user: ${GRAFANA_ADMIN_USER})"
echo "cAdvisor:   http://${IP_ADDR}:8080"
echo ""
echo "Config lives in ${INSTALL_DIR} (edit prometheus/prometheus.yaml for scrape targets,"
echo ".env for credentials/retention, then: cd ${INSTALL_DIR} && docker compose restart)"
