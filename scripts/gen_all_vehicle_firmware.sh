#!/usr/bin/env bash
# File: scripts/generate_all_vehicle_firmware.sh
# Purpose: Generate .ino + .hex + metadata + delivery ZIPs for all configured vehicles
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 2.3.1

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
META_DIR="$FIRMWARE_DIR/metadata/per_customer"
SRC_DIR="$FIRMWARE_DIR/sources"
BIN_DIR="$FIRMWARE_DIR/binaries"
MANIFEST="$ROOT_DIR/sha256_manifest.txt"
RENDER_SCRIPT="$SCRIPT_DIR/render_config_to_ino.py"
SCHEMA_PATH="$ROOT_DIR/config/schema/flash_pattern.schema.json"
TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
FQBN="${FQBN:-arduino:avr:nano:cpu=atmega328old}"

mkdir -p "$OUTPUT_DIR" "$ZIP_DIR" "$LOG_DIR" "$META_DIR" "$SRC_DIR" "$BIN_DIR"
rm -f "$MANIFEST"

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
echo "GENERATOR: ALL VEHICLE FIRMWARE PACKAGE BUILDER"
echo "Start Time : $TIMESTAMP"
echo "Config Dir : $CONFIG_DIR"
echo "Output Dir : $ZIP_DIR"
echo "────────────────────────────────────────────────────────────"

shopt -s nullglob
CONFIG_FILES=("$CONFIG_DIR"/*.json)

if [[ ${#CONFIG_FILES[@]} -eq 0 ]]; then
  echo "[✗] No config files found in $CONFIG_DIR"
  exit 1
fi

for config in "${CONFIG_FILES[@]}"; do
  ((total++))
  name="$(basename "$config" .json)"
  vehicle_out="$OUTPUT_DIR/$name"
  build_log="$LOG_DIR/${name}_build.log"
  ino_path="$SRC_DIR/${name}.ino"
  meta_path="$META_DIR/${name}.json"
  hex_path="$BIN_DIR/${name}.hex"
  manifest_path="$vehicle_out/manifest.json"

  echo "→ Processing: $name"

  rm -rf "$vehicle_out"
  mkdir -p "$vehicle_out"

  echo "  [•] Rendering firmware..."
  if ! python3 "$RENDER_SCRIPT" \
      --input "$config" \
      --output "$ino_path" \
      --meta "$meta_path" \
      --schema "$SCHEMA_PATH" \
      --template "$FIRMWARE_DIR/templates/BrakeFlasher.ino.j2" \
      > "$build_log" 2>&1; then
    echo "  [✗] Render failed → $build_log"
    ((fail++))
    continue
  fi

  echo "  [•] Compiling firmware..."
  if ! arduino-cli compile \
      --fqbn "$FQBN" \
      --build-path "$vehicle_out/build" \
      "$ino_path" >> "$build_log" 2>&1; then
    echo "  [✗] Compilation failed → $build_log"
    ((fail++))
    continue
  fi

  compiled_hex="$(find "$vehicle_out/build" -name '*.hex' | head -n1)"
  if [[ ! -f "$compiled_hex" ]]; then
    echo "  [✗] HEX missing → $compiled_hex"
    ((fail++))
    continue
  fi

  cp "$compiled_hex" "$hex_path"
  cp "$hex_path" "$vehicle_out/BrakeFlasher.ino.hex"
  cp "$ino_path" "$vehicle_out/BrakeFlasher.ino"
  cp "$meta_path" "$vehicle_out/firmware_version.json"
  cp "$config" "$vehicle_out/input_config.json"
  rm -rf "$vehicle_out/build"

  # Create manifest
  jq -n --arg name "$name" --arg time "$TIMESTAMP" --arg version "$(jq -r .version "$meta_path")" \
    '{
      vehicle: $name,
      version: $version,
      generated: $time
    }' > "$manifest_path"

  # Package ZIP
  ZIP_FILE="$ZIP_DIR/${name}_${TIMESTAMP}.zip"
  (cd "$vehicle_out" && zip -qr "$ZIP_FILE" .)
  echo "  [✓] ZIP complete: $(basename "$ZIP_FILE")"

  # SHA256
  sha256sum "$ino_path" >> "$MANIFEST"
  sha256sum "$meta_path" >> "$MANIFEST"
  sha256sum "$hex_path" >> "$MANIFEST"
  sha256sum "$ZIP_FILE" >> "$MANIFEST"

  ((success++))
done

# ─────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────
echo "────────────────────────────────────────────────────────────"
echo "SUMMARY"
echo "Generated     : $success"
echo "Failed        : $fail"
echo "Total         : $total"
echo "Output ZIPs   : $ZIP_DIR"
echo "SHA Manifest  : $MANIFEST"
echo "────────────────────────────────────────────────────────────"

[[ "$fail" -gt 0 ]] && exit 1 || exit 0
