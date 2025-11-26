#!/bin/bash

# Config
OUTPUT="/var/lib/node_exporter/textfile_collector/sdmon.prom"
DEVICE="/dev/mmcblk0"
SDMON_BIN="/usr/local/bin/sdmon"
PATH="/usr/local/bin:/usr/bin:/bin"

# === Ensure sdmon binary exists ===
if [ ! -x "$SDMON_BIN" ]; then
  echo "ERROR: sdmon binary not found or not executable at $SDMON_BIN" >&2
  exit 1
fi

# === Ensure jq exists ===
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq not found (install with 'sudo apt install jq')" >&2
  exit 1
fi

# === Get SDMON data ===
SDMON_JSON=$("$SDMON_BIN" "$DEVICE" 2>/dev/null)

# Validate output
if [ -z "$SDMON_JSON" ]; then
  echo "No sdmon output. Is this an industrial SD card?" >&2
  exit 1
fi

# === Parse JSON ===
GOOD_BLOCK_RATE=$(echo "$SDMON_JSON" | jq '.goodBlockRatePercent // 0')
ENDURANCE_LEFT=$(echo "$SDMON_JSON" | jq '.enduranceRemainLifePercent // 0')
AVG_ERASE_COUNT=$(echo "$SDMON_JSON" | jq '.avgEraseCount // 0')
TOTAL_ERASE_COUNT=$(echo "$SDMON_JSON" | jq '.totalEraseCount // 0')
SPARE_BLOCK_COUNT=$(echo "$SDMON_JSON" | jq '.spareBlockCount // 0')
BAD_BLOCKS=$(echo "$SDMON_JSON" | jq '.laterBadBlockCount // 0')
POWER_UPS=$(echo "$SDMON_JSON" | jq '.powerUpCount // 0')

# === Write Prometheus metrics ===
# Writing to a temp file first to ensure atomicity
TEMP_FILE="${OUTPUT}.tmp"

cat <<METRICS > "$TEMP_FILE"
# HELP sdcard_good_block_rate_percent Good block rate (%)
# TYPE sdcard_good_block_rate_percent gauge
sdcard_good_block_rate_percent $GOOD_BLOCK_RATE

# HELP sdcard_endurance_remaining_percent Remaining estimated endurance (%)
# TYPE sdcard_endurance_remaining_percent gauge
sdcard_endurance_remaining_percent $ENDURANCE_LEFT

# HELP sdcard_avg_erase_count Average erase count
# TYPE sdcard_avg_erase_count gauge
sdcard_avg_erase_count $AVG_ERASE_COUNT

# HELP sdcard_total_erase_count Total erase count
# TYPE sdcard_total_erase_count counter
sdcard_total_erase_count $TOTAL_ERASE_COUNT

# HELP sdcard_spare_block_count Number of spare blocks remaining
# TYPE sdcard_spare_block_count gauge
sdcard_spare_block_count $SPARE_BLOCK_COUNT

# HELP sdcard_later_bad_block_count Number of bad blocks detected after manufacture
# TYPE sdcard_later_bad_block_count gauge
sdcard_later_bad_block_count $BAD_BLOCKS

# HELP sdcard_powerup_count Total power-up count
# TYPE sdcard_powerup_count counter
sdcard_powerup_count $POWER_UPS
METRICS

mv "$TEMP_FILE" "$OUTPUT"
EOF