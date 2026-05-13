# Pi Setup - Raspberry Pi Monitoring Infrastructure

Complete monitoring and home automation infrastructure for Raspberry Pi clusters with Prometheus, Grafana, Node Exporter, and Home Assistant.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Components](#components)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Network Configuration](#network-configuration)
- [Troubleshooting](#troubleshooting)
- [File Structure](#file-structure)

## 🎯 Overview

This repository provides automated setup scripts and configurations for:

1. **System Monitoring**: Prometheus + Grafana for cluster metrics visualization
2. **Node Metrics**: Node Exporter for hardware and OS metrics on each Pi
3. **SD Card Monitoring**: SDMON for SD card health and performance metrics
4. **Containerization**: Docker and Docker Compose for service orchestration
5. **Home Automation**: Home Assistant with PostgreSQL for IoT management

Perfect for:
- Monitoring Raspberry Pi clusters
- Tracking SD card health over time
- Visualizing system metrics in Grafana
- Running containerized applications
- Home automation projects

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    MONITORING INFRASTRUCTURE                     │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────────────────────┐
                    │   Prometheus + Grafana       │
                    │   (Central Monitoring)       │
                    │   Port 9090 | 3000 | 8080   │
                    └──────────────────────────────┘
                              ▲
                    ┌─────────┘────────────────────┐
                    │         Docker Network       │
                    │        (monitoring)          │
                    └─────────────────────────────┘

     ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
     │  Pi Ultra 1  │  │  Pi Ultra 2  │  │  Pi Ultra 3  │
     │              │  │              │  │              │
     │ Node Exp     │  │ Node Exp     │  │ Node Exp     │
     │ SDMON        │  │ SDMON        │  │ SDMON        │
     │ Port 9100    │  │ Port 9100    │  │ Port 9100    │
     └──────────────┘  └──────────────┘  └──────────────┘
             │                 │                │
             └─────────────────┼─────────────────┘
                       (pulls metrics)

┌─────────────────────────────────────────────────────────────────┐
│                    HOME ASSISTANT SETUP                         │
└─────────────────────────────────────────────────────────────────┘

         ┌──────────────────────────────────┐
         │  Home Assistant Application      │
         │  + PostgreSQL/TimescaleDB        │
         │  Port 8000 | 8001                │
         └──────────────────────────────────┘
```

## 📦 Components

| Component | Location | Port | Purpose |
|-----------|----------|------|---------|
| **Node Exporter** | `node_exporter_setup/` | 9100 | Hardware/OS metrics on each Pi |
| **SDMON** | `sdmon_setup/` | - | SD card health monitoring |
| **Docker** | `docker_setup/` | - | Container runtime and orchestration |
| **Prometheus** | `prometheus_grafana_setup/` | 9090 | Metrics collection and storage |
| **Grafana** | `prometheus_grafana_setup/` | 3000 | Metrics visualization |
| **cAdvisor** | `prometheus_grafana_setup/` | 8080 | Container metrics |
| **Home Assistant** | `home_assistant_setup/` | 8000 | Home automation app |
| **PostgreSQL** | `home_assistant_setup/` | 5432 | Database for Home Assistant |

## 🚀 Quick Start

### Option 1: Full Automated Setup

Clone this repository on your Raspberry Pi and run the complete setup:

```bash
git clone https://github.com/anji5h/pi_setup.git
cd pi_setup
```

Then follow the step-by-step guide below.

### Option 2: Install Individual Components

Each component has its own setup script. Pick what you need:

```bash
# Install just Node Exporter
cd node_exporter_setup && sudo ./install.sh

# Install just Docker
cd docker_setup && sudo ./install.sh

# Install just Prometheus/Grafana
cd prometheus_grafana_setup && docker compose up -d

# Install Home Assistant
cd home_assistant_setup && ./home_assistant/deploy_app.sh
```

## 📚 Detailed Setup

### Step 1: Docker Setup (Required)

Docker is the foundation for Prometheus, Grafana, and Home Assistant.

```bash
cd docker_setup
chmod +x install.sh
sudo ./install.sh

# Log out and log back in (or reboot) for permissions to take effect
logout
```

**See**: [docker_setup/README.md](docker_setup/README.md)

---

### Step 2: Node Exporter Setup (Required for monitoring)

Install on **each Raspberry Pi** that you want to monitor:

```bash
cd node_exporter_setup
chmod +x install.sh
sudo ./install.sh
```

**Verify**: `curl http://<pi_ip>:9100/metrics`

**See**: [node_exporter_setup/README.md](node_exporter_setup/README.md)

---

### Step 3: SDMON Setup (Optional but recommended)

Monitor SD card health on each Pi:

```bash
cd sdmon_setup
chmod +x install.sh
sudo ./install.sh

# Then setup the exporter
chmod +x setup_exporter.sh
sudo ./setup_exporter.sh
```

**See**: [sdmon_setup/README.md](sdmon_setup/README.md)

---

### Step 4: Prometheus & Grafana Setup (Recommended)

Run on the **main monitoring Pi** (preferably one with more storage):

```bash
cd prometheus_grafana_setup
docker compose up -d
```

**Access**:
- Prometheus: http://<pi_ip>:9090
- Grafana: http://<pi_ip>:3000
- cAdvisor: http://<pi_ip>:8080

**See**: [prometheus_grafana_setup/README.md](prometheus_grafana_setup/README.md)

---

### Step 5: Home Assistant Setup (Optional)

Run on your main Pi for home automation:

```bash
cd home_assistant_setup
./home_assistant/deploy_app.sh
```

**Access**: http://<pi_ip>:8000

**See**: [home_assistant_setup/README.md](home_assistant_setup/README.md)

---

## 🌐 Network Configuration

### Target Configuration

Edit `prometheus_grafana_setup/prometheus/prometheus.yaml` to add your monitored Pis:

```yaml
scrape_configs:
  - job_name: 'my_pi_cluster'
    static_configs:
      - targets:
          - '192.168.1.10:9100'   # Pi 1
          - '192.168.1.11:9100'   # Pi 2
          - '192.168.1.12:9100'   # Pi 3
        labels:
          group: 'my_cluster'
```

Then restart Prometheus: `docker compose restart prometheus`

### Port Overview

| Port | Service | Access | Security |
|------|---------|--------|----------|
| 9100 | Node Exporter | Internal scraping | No auth |
| 9090 | Prometheus | Web UI, API | No auth (add reverse proxy) |
| 3000 | Grafana | Web UI, API | User/password protected |
| 8080 | cAdvisor | Web UI | No auth |
| 8000 | Home Assistant | Web UI | Application auth |
| 5432 | PostgreSQL | Database | User/password protected |

### Firewall Rules

Restrict access to your network:

```bash
# Allow only local network to Prometheus
sudo ufw allow from 192.168.1.0/24 to any port 9090

# Allow only local network to Grafana
sudo ufw allow from 192.168.1.0/24 to any port 3000
```

## 📊 Dashboard Setup

After Prometheus and Grafana are running:

1. Access Grafana: http://<pi_ip>:3000
2. Login with configured credentials (default: anjish / T@rtu879)
3. Add Prometheus as a data source:
   - Name: `Prometheus`
   - URL: `http://prometheus:9090`
   - Click "Save & Test"
4. Import dashboards or create new ones

### Popular Dashboard IDs

- Node Exporter: 1860
- Docker Containers: 11074
- System Overview: 3662

## 📁 File Structure

```
pi_setup/
│
├── node_exporter_setup/          # Node Exporter monitoring
│   ├── install.sh
│   └── README.md
│
├── sdmon_setup/                  # SD card monitoring
│   ├── install.sh
│   ├── setup_exporter.sh
│   ├── sdmon_exporter/
│   └── README.md
│
├── docker_setup/                 # Docker installation
│   ├── install.sh
│   └── README.md
│
├── prometheus_grafana_setup/     # Metrics collection & visualization
│   ├── docker-compose.yml
│   ├── prometheus/
│   │   ├── prometheus.yaml
│   │   └── (additional configs)
│   ├── grafana/
│   │   └── provisioning/
│   └── README.md
│
├── home_assistant_setup/         # Home automation
│   ├── docker-compose.yml
│   ├── .env
│   ├── home_assistant/
│   │   ├── deploy_app.sh
│   │   ├── init.sh
│   │   └── (application files)
│   └── README.md
│
├── README.md                     # This file
├── setup.txt                     # Quick setup reference
└── .git/
```

## 🔧 Common Tasks

### Add new Pi to monitoring

1. Install Node Exporter: `cd node_exporter_setup && sudo ./install.sh`
2. Get Pi's IP: `hostname -I`
3. Edit `prometheus_grafana_setup/prometheus/prometheus.yaml`
4. Add IP to targets list
5. Restart Prometheus: `docker compose restart prometheus`

### Change Grafana password

```bash
cd prometheus_grafana_setup
# Edit docker-compose.yml and change GF_SECURITY_ADMIN_PASSWORD
docker compose restart grafana
```

### View real-time logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f prometheus
```

### Backup Prometheus data

```bash
cd prometheus_grafana_setup
docker compose stop prometheus
cp -r prometheus_data prometheus_data.backup
docker compose start prometheus
```

### Update services to latest versions

```bash
cd prometheus_grafana_setup
docker compose pull
docker compose up -d
```

## Troubleshooting

### Node Exporter metrics not appearing in Prometheus

1. Verify Node Exporter is running: `curl http://<pi_ip>:9100/metrics`
2. Check Prometheus targets: http://<pi_ip>:9090/targets
3. Verify correct IPs in `prometheus.yaml`
4. Check firewall allows port 9100
5. View Prometheus logs: `docker compose logs prometheus`

### Grafana won't start

1. Check disk space: `df -h`
2. Check logs: `docker compose logs grafana`
3. Verify port 3000 is available: `lsof -i :3000`
4. Restart Docker: `sudo systemctl restart docker`

### High memory usage

1. Check what's consuming memory: `docker compose stats`
2. Reduce Prometheus scrape frequency in `prometheus.yaml`
3. Reduce data retention: edit `docker-compose.yml`
4. Clean up old data: `docker system prune -a`

### SDMON exporter not running

1. Check timer status: `sudo systemctl status sdmon_exporter.timer`
2. View logs: `sudo journalctl -u sdmon_exporter.service -f`
3. Check metrics exist: `ls /var/lib/node_exporter/textfile_collector/`
4. Re-run setup: `cd sdmon_setup && sudo ./setup_exporter.sh`

### Home Assistant won't connect to database

1. Check PostgreSQL is running: `docker compose ps postgres`
2. Verify .env file exists: `cat .env`
3. Check connection string is correct
4. View app logs: `docker compose logs app`
5. Test database directly: `docker compose exec postgres psql -U postgres -d home_assistant`

## 📖 Documentation

- [Node Exporter Setup](node_exporter_setup/README.md)
- [SDMON Setup](sdmon_setup/README.md)
- [Docker Setup](docker_setup/README.md)
- [Prometheus & Grafana Setup](prometheus_grafana_setup/README.md)
- [Home Assistant Setup](home_assistant_setup/README.md)

## Security Notes

- Change default Grafana password in `docker-compose.yml`
- Change default Home Assistant PostgreSQL password in `.env`
- Use strong passwords (12+ characters with mixed case, numbers, symbols)
- Restrict access to ports 9090, 3000, 8000 to trusted networks only
- Regularly update Docker images: `docker compose pull && docker compose up -d`
- Back up important data regularly

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Node Exporter GitHub](https://github.com/prometheus/node_exporter)
- [Docker Documentation](https://docs.docker.com/)
- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/)

## Support & Troubleshooting

For detailed troubleshooting, see the README.md in each component folder:
- Node Exporter issues: [node_exporter_setup/README.md](node_exporter_setup/README.md)
- SDMON issues: [sdmon_setup/README.md](sdmon_setup/README.md)
- Docker issues: [docker_setup/README.md](docker_setup/README.md)
- Prometheus/Grafana issues: [prometheus_grafana_setup/README.md](prometheus_grafana_setup/README.md)
- Home Assistant issues: [home_assistant_setup/README.md](home_assistant_setup/README.md)

## 📄 License
MIT LICENSE

**Last Updated**: 2026
**Supported**: Raspberry Pi 4, 5 (32-bit and 64-bit OS)
