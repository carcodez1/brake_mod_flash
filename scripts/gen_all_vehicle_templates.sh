#!/usr/bin/env bash
# File: scripts/gen_all_vehicle_templates.sh
# Purpose: Render all .ino templates + metadata from all vehicle configs
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 2.0.0

set -euo pipefail

# ─────────────────────────────────────────────────────────────
# PATHS
# ─────────────────────────────────────────────────────────────
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$ROOT_DIR/config/vehicles"
OUTPUT_DIR="$ROOT_DIR/output"
LOG_DIR="$ROOT_DIR/logs"
RENDER_SCRIPT="$ROOT_DIR/scripts/render_config_to_ino.py"

mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# ─────────────────────────────────────────────────────────────
# COUNTERS
# ─────────────────────────────────────────────────────────────
total=0
success=0
fail=0

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
echo "────────────────────────────────────────────────────────────"
echo "RENDERING FIRMWARE TEMPLATES (NO COMPILE)"
echo "Start Time : $TIMESTAMP"
echo "Input Dir  : $CONFIG_DIR"
echo "Output Dir : $OUTPUT_DIR"
echo "────────────────────────────────────────────────────────────"

# ─────────────────────────────────────────────────────────────
# PROCESS EACH CONFIG
# ─────────────────────────────────────────────────────────────
for config_file in "$CONFIG_DIR"/*.json; do
  ((total++))
  vehicle_name=$(basename "$config_file" .json)
  vehicle_dir="$OUTPUT_DIR/$vehicle_name"
  vehicle_log="$LOG_DIR/${vehicle_name}_render.log"

  echo "→ Rendering: $vehicle_name"

  rm -rf "$vehicle_dir"
  mkdir -p "$vehicle_dir"

  if ! python3 "$RENDER_SCRIPT" \
      --config "$config_file" \
      --output "$vehicle_dir/BrakeFlasher.ino" \
      --meta "$vehicle_dir/version.json" > "$vehicle_log" 2>&1; then
    echo "  [ERROR] Failed – see $vehicle_log"
    ((fail++))
    continue
  fi

  echo "  [✓] Template ready: $vehicle_dir/BrakeFlasher.ino"
  ((success++))
done

# ─────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────
echo "────────────────────────────────────────────────────────────"
echo "SUMMARY"
echo "Total Configs  : $total"
echo "Templates OK   : $success"
echo "Failures       : $fail"
echo "Output Path    : $OUTPUT_DIR"
echo "────────────────────────────────────────────────────────────"

if [[ "$fail" -gt 0 ]]; then
  echo "RECOMMENDATION: Review logs in $LOG_DIR/*.log"
  exit 1
else
  echo "All templates rendered successfully."
  exit 0
fi
