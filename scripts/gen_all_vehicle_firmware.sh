#!/usr/bin/env bash
# File: scripts/generate_all_vehicle_firmware.sh
# Purpose: Generate .ino + .hex + metadata + delivery ZIPs for all configured vehicles
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 2.2.0

set -euo pipefail

# ─────────────────────────────────────────────────────────────
# DIRECTORIES
# ─────────────────────────────────────────────────────────────
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$ROOT_DIR/config/vehicles"
OUTPUT_DIR="$ROOT_DIR/output"
FIRMWARE_DIR="$ROOT_DIR/firmware"
SCRIPT_DIR="$ROOT_DIR/scripts"
ZIP_DIR="$OUTPUT_DIR/zips"
LOG_DIR="$ROOT_DIR/logs"

RENDER_SCRIPT="$SCRIPT_DIR/render_config_to_ino.py"
TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")

mkdir -p "$OUTPUT_DIR" "$ZIP_DIR" "$LOG_DIR"

# ─────────────────────────────────────────────────────────────
# COUNTERS
# ─────────────────────────────────────────────────────────────
total=0
success=0
fail=0

# ─────────────────────────────────────────────────────────────
# MAIN LOOP
# ─────────────────────────────────────────────────────────────
echo "────────────────────────────────────────────────────────────"
echo "GENERATOR: ALL VEHICLE FIRMWARE"
echo "Start Time : $TIMESTAMP"
echo "Config Dir : $CONFIG_DIR"
echo "Output Dir : $ZIP_DIR"
echo "────────────────────────────────────────────────────────────"

for config in "$CONFIG_DIR"/*.json; do
  ((total++))
  vehicle_name="$(basename "$config" .json)"
  vehicle_out="$OUTPUT_DIR/$vehicle_name"
  vehicle_log="$LOG_DIR/${vehicle_name}_build.log"
  version_json="$vehicle_out/version.json"

  echo "→ Processing: $vehicle_name"

  # Clean + create output folder
  rm -rf "$vehicle_out"
  mkdir -p "$vehicle_out"

  # Render .ino + metadata
  if ! python3 "$RENDER_SCRIPT" \
      --config "$config" \
      --output "$vehicle_out/BrakeFlasher.ino" \
      --meta "$version_json" >"$vehicle_log" 2>&1; then
    echo "  [ERROR] Firmware render failed – see: $vehicle_log"
    ((fail++))
    continue
  fi

  # Compile .ino → .hex
  echo "  Compiling..."
  if ! arduino-cli compile \
      --fqbn arduino:avr:nano:cpu=atmega328old \
      --build-path "$vehicle_out/build" \
      "$vehicle_out/BrakeFlasher.ino" >>"$vehicle_log" 2>&1; then
    echo "  [ERROR] Compilation failed – see: $vehicle_log"
    ((fail++))
    continue
  fi

  HEX_FILE="$vehicle_out/build/BrakeFlasher.ino.hex"
  if [ ! -f "$HEX_FILE" ]; then
    echo "  [ERROR] HEX file missing after compile"
    ((fail++))
    continue
  fi

  cp "$HEX_FILE" "$vehicle_out/BrakeFlasher.ino.hex"
  rm -rf "$vehicle_out/build"

  # Package .zip
  ZIP_FILE="$ZIP_DIR/${vehicle_name}_${TIMESTAMP}.zip"
  (
    cd "$vehicle_out"
    zip -qr "$ZIP_FILE" .
  )
  echo "  [✓] Generated: $(basename "$ZIP_FILE")"
  ((success++))
done

# ─────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────
echo "────────────────────────────────────────────────────────────"
echo "SUMMARY"
echo "Total Configs  : $total"
echo "Successful     : $success"
echo "Failed         : $fail"
echo "ZIP Output Dir : $ZIP_DIR"
echo "────────────────────────────────────────────────────────────"

if [[ "$fail" -gt 0 ]]; then
  echo "RECOMMENDATION: Review logs in $LOG_DIR/*.log for failure reasons."
  exit 1
else
  echo "All vehicle firmware packages built successfully."
  exit 0
fi
