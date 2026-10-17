#!/bin/bash
# Ultra cluster setup: installs Prometheus Node Exporter.
# Run as a regular user with sudo privileges (not as root): ./ultra_cluster_setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/install/node_exporter.sh"
