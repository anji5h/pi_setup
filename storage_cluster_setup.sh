#!/bin/bash
# High-endurance / industrial cluster setup: Node Exporter + sdmon + custom
# sdmon Prometheus exporter (SD card health metrics).
# Run as a regular user with sudo privileges (not as root): ./storage_cluster_setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/install/node_exporter.sh"
"$SCRIPT_DIR/install/sdmon.sh"
"$SCRIPT_DIR/install/sdmon_exporter.sh"

echo "--- Installation Summary ---"
systemctl is-active --quiet node_exporter && echo "node_exporter:        RUNNING" || echo "node_exporter:        FAILED"
systemctl is-active --quiet sdmon_exporter.timer && echo "sdmon_exporter.timer: RUNNING" || echo "sdmon_exporter.timer: FAILED"
echo "Metrics: http://$(hostname -I | awk '{print $1}'):9100/metrics"
