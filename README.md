# Pi Setup - Raspberry Pi Monitoring Infrastructure

Monitoring infrastructure for a Raspberry Pi cluster: Prometheus + Grafana on a
central server, Node Exporter (and sdmon for SD card health) on each Pi.

Home automation (Home Assistant) is a separate, unrelated workload on this
network and is intentionally out of scope for this README — see
`home_assistant_setup/` if you need it.

## Architecture

```
┌───────────────────────────────┐
│     Monitoring Server         │
│  Prometheus (9090)            │
│  Grafana    (3000)            │
│  cAdvisor   (8080)            │
└───────────────────────────────┘
              ▲  (scrapes :9100)
  ┌───────────┼──────────────────────────────┐
  │           │                              │
┌─────────────┴───┐  ┌──────────────┐  ┌──────────────┐
│  pi-ultra-1..5   │  │ pi-hend-1..5 │  │ pi-ind-1..5  │
│  node_exporter   │  │ node_exporter│  │ node_exporter│
│                  │  │ + sdmon      │  │ + sdmon      │
└──────────────────┘  └──────────────┘  └──────────────┘
```

- **Ultra cluster**: Ultra SD cards, monitored with Node Exporter only.
- **High-endurance / Industrial clusters**: also run `sdmon` to track SD card
  wear (erase counts, bad blocks, remaining endurance), exported to
  Prometheus via Node Exporter's textfile collector.

## Scripts

Each target runs exactly one self-contained script (no need to clone
sub-folders or chain multiple installers). Clone this repo on the target
machine, then run the script for its role:

| Script | Run on | Installs |
|--------|--------|----------|
| [`ultra_cluster_setup.sh`](ultra_cluster_setup.sh) | pi-ultra-1..5 | Node Exporter |
| [`storage_cluster_setup.sh`](storage_cluster_setup.sh) | pi-hend-1..5, pi-ind-1..5 | Node Exporter + sdmon + custom sdmon exporter |
| [`monitoring_server_setup.sh`](monitoring_server_setup.sh) | central monitoring server | Docker + Prometheus + Grafana + cAdvisor |

All three are idempotent (safe to re-run) and auto-detect CPU architecture
(arm64/armv7) — no manual editing required.

### Ultra cluster

```bash
git clone https://github.com/anji5h/pi_setup.git ~/pi_setup
cd ~/pi_setup
./ultra_cluster_setup.sh
```

Verify: `curl http://<pi_ip>:9100/metrics`

### High-endurance / Industrial clusters

```bash
git clone https://github.com/anji5h/pi_setup.git ~/pi_setup
cd ~/pi_setup
./storage_cluster_setup.sh
```

Verify: `curl http://<pi_ip>:9100/metrics | grep sdcard`

### Monitoring server

Requires a Grafana admin password to be set explicitly (no default is
hardcoded — never commit a real password to this repo):

```bash
git clone https://github.com/anji5h/pi_setup.git ~/pi_monitoring_repo
cd ~/pi_monitoring_repo
GRAFANA_ADMIN_PASSWORD='choose-a-strong-password' ./monitoring_server_setup.sh
```

This installs Docker (if not already present) and starts Prometheus,
Grafana, and cAdvisor via Docker Compose in `~/pi-monitoring` (override with
`INSTALL_DIR`).

- Prometheus: `http://<server_ip>:9090`
- Grafana: `http://<server_ip>:3000`
- cAdvisor: `http://<server_ip>:8080`

Scrape targets are defined in the embedded `prometheus.yaml` the script
writes to `$INSTALL_DIR/prometheus/prometheus.yaml`. If a Pi's IP changes,
edit that file and run `docker compose restart prometheus` from
`$INSTALL_DIR`.

## Configuration (environment variables)

| Script | Variable | Default | Purpose |
|--------|----------|---------|---------|
| ultra / storage | `NODE_EXPORTER_VERSION` | `1.12.1` | Node Exporter version to install |
| storage | `SDMON_VERSION` | `0.9.0` | sdmon version to install |
| storage | `SD_DEVICE` | `/dev/mmcblk0` | SD card block device to monitor |
| monitoring server | `GRAFANA_ADMIN_USER` | `admin` | Grafana admin username |
| monitoring server | `GRAFANA_ADMIN_PASSWORD` | *(required, no default)* | Grafana admin password |
| monitoring server | `PROM_RETENTION` | `180d` | Prometheus data retention |
| monitoring server | `INSTALL_DIR` | `~/pi-monitoring` | Where compose files + volumes live |

## Security notes

- A Grafana admin password was previously hardcoded in this repo's git
  history (`prometheus_grafana_setup/docker-compose.yml`). Treat that
  password as compromised and rotate it — the new script refuses to run
  without an explicit `GRAFANA_ADMIN_PASSWORD`.
- Restrict access to ports 9090 (Prometheus), 3000 (Grafana), and 8080
  (cAdvisor) to trusted networks.
- Node Exporter (9100) has no authentication; keep it on an internal network.

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Node Exporter GitHub](https://github.com/prometheus/node_exporter)
- [sdmon GitHub](https://github.com/Ognian/sdmon)
- [Docker Documentation](https://docs.docker.com/)

## License
MIT LICENSE
