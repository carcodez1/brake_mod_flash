#!/usr/bin/env bash
# File: scripts/compile_all_firmware.sh
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assignment
# Purpose: Compile all .ino firmware in firmware/sources to .hex in firmware/binaries
# Version: 1.0.0

set -euo pipefail

SRC_DIR="firmware/sources"
BIN_DIR="firmware/binaries"
LOG_DIR="logs"
FQBN="arduino:avr:nano:cpu=atmega328old"

mkdir -p "$BIN_DIR" "$LOG_DIR"

echo "──────────────────────────────────────────────"
echo "COMPILER: ALL .INO FILES → .HEX"
echo "Source Dir : $SRC_DIR"
echo "Binary Dir : $BIN_DIR"
echo "──────────────────────────────────────────────"

total=0
success=0
fail=0

for ino_file in "$SRC_DIR"/*.ino; do
  ((total++))
  name=$(basename "$ino_file" .ino)
  hex_out="$BIN_DIR/${name}.hex"
  build_dir="$SRC_DIR/${name}_build"
  log_file="$LOG_DIR/compile_${name}.log"

  echo "→ Compiling: $name"

  if ! arduino-cli compile \
      --fqbn "$FQBN" \
      --build-path "$build_dir" \
      "$ino_file" >"$log_file" 2>&1; then
    echo "  [✗] Compile failed: see $log_file"
    ((fail++))
    continue
  fi

  # Copy and clean
  cp "$build_dir"/*.hex "$hex_out"
  rm -rf "$build_dir"

  echo "  [✓] Compiled: $hex_out"
  ((success++))
done

echo "──────────────────────────────────────────────"
echo "SUMMARY"
echo "Total    : $total"
echo "Success  : $success"
echo "Failed   : $fail"
echo "Output   : $BIN_DIR"
echo "──────────────────────────────────────────────"

if [[ "$fail" -gt 0 ]]; then
  echo "Some compilations failed. Check logs in $LOG_DIR."
  exit 1
else
  echo "All firmware compiled successfully."
  exit 0
fi
