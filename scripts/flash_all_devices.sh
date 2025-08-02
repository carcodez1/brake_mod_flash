#!/usr/bin/env bash
# File: scripts/flash_all_devices.sh
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assignment
# Purpose: Flash all .hex files in firmware/binaries/ to connected Arduino devices
# Version: 1.0.0

set -euo pipefail

BIN_DIR="firmware/binaries"
LOG_DIR="logs"
PORTS=("/dev/ttyUSB0" "/dev/ttyUSB1" "/dev/ttyUSB2")  # Expandable
FQBN="arduino:avr:nano:cpu=atmega328old"

mkdir -p "$LOG_DIR"

echo "──────────────────────────────────────────────"
echo "FLASHER: ALL .HEX FILES TO CONNECTED BOARDS"
echo "Binary Dir : $BIN_DIR"
echo "Ports      : ${PORTS[*]}"
echo "──────────────────────────────────────────────"

total=0
success=0
fail=0

for hex_file in "$BIN_DIR"/*.hex; do
  ((total++))
  name=$(basename "$hex_file" .hex)
  flashed=false

  for port in "${PORTS[@]}"; do
    if [ -c "$port" ]; then
      log_file="$LOG_DIR/flash_${name}_${port##*/}.log"
      echo "→ Flashing $name to $port..."

      if avrdude -v \
          -patmega328p -carduino -P"$port" -b115200 -D \
          -Uflash:w:"$hex_file":i >"$log_file" 2>&1; then
        echo "  [✓] Flashed: $hex_file → $port"
        flashed=true
        ((success++))
        break
      else
        echo "  [✗] Flash failed on $port – see $log_file"
      fi
    fi
  done

  if [ "$flashed" = false ]; then
    echo "  [✗] No available ports or all flash attempts failed for $name"
    ((fail++))
  fi
done

echo "──────────────────────────────────────────────"
echo "SUMMARY"
echo "Total    : $total"
echo "Flashed  : $success"
echo "Failed   : $fail"
echo "──────────────────────────────────────────────"

if [[ "$fail" -gt 0 ]]; then
  echo "Some flash operations failed. Check logs in $LOG_DIR."
  exit 1
else
  echo "All devices flashed successfully."
  exit 0
fi
