#!/usr/bin/env bash
# File: scripts/render_all_vehicles.sh
# Purpose: Render all vehicle configs to INO + metadata + delivery ZIPs
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.0.0

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$ROOT_DIR/config/vehicles"
SRC_DIR="$ROOT_DIR/firmware/sources"
META_DIR="$ROOT_DIR/firmware/metadata"
ZIP_DIR="$ROOT_DIR/output/zips"
SCRIPT="$ROOT_DIR/scripts/render_config_to_ino.py"
LOG="$ROOT_DIR/logs/render_all.log"

mkdir -p "$SRC_DIR" "$META_DIR" "$ZIP_DIR" "$(dirname "$LOG")"

echo "[*] Rendering all vehicles from: $CONFIG_DIR" | tee "$LOG"

for json_file in "$CONFIG_DIR"/*.json; do
  vehicle_id="$(basename "$json_file" .json)"
  ino_out="$SRC_DIR/${vehicle_id}.ino"
  meta_out="$META_DIR/${vehicle_id}_firmware_version.json"
  zip_out="$ZIP_DIR/${vehicle_id}.zip"

  echo "─── Processing $vehicle_id ───" | tee -a "$LOG"

  # Run renderer
  python3 "$SCRIPT" \
    --input "$json_file" \
    --output "$ino_out" \
    --meta "$meta_out" \
    >> "$LOG" 2>&1

  # Extract mode/compliance for trace
  pattern_mode=$(jq -r '.pattern_mode' "$json_file")
  compliance=$(jq -r '.metadata.compliance_level' "$json_file")

  # Assemble ZIP
  zip -j "$zip_out" "$json_file" "$ino_out" "$meta_out" >> "$LOG"

  echo "[✓] Rendered: $vehicle_id → mode=$pattern_mode, compliance=$compliance" | tee -a "$LOG"
done

echo "[✓] All .ino files generated and packaged into ZIPs → $ZIP_DIR"

