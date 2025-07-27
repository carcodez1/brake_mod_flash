#!/usr/bin/env bash
# File: scripts/flash_arduino.sh
# Purpose: Compile and upload .ino to Arduino Nano (Production Hardened)
set -euo pipefail

PORT="${PORT:-/dev/ttyUSB0}"
FQBN="${FQBN:-arduino:avr:nano}"
INO="firmware/BrakeFlasher.ino"

if [[ ! -f "$INO" ]]; then
  echo "[✗] ERROR: Firmware file not found: $INO"
  exit 1
fi

echo "[*] Target Port: $PORT"
echo "[*] Target Board: $FQBN"
echo "[*] Compiling firmware..."
arduino-cli compile --fqbn "$FQBN" "$INO"

echo "[*] Uploading firmware to $PORT..."
arduino-cli upload -p "$PORT" --fqbn "$FQBN" "$INO"

echo "[✓] Flash successful."
