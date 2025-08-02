#!/usr/bin/env bash
# File: scripts/bootstrap_flash.sh
# Purpose: Bootstrap flashing environment and validate Arduino Nano setup
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 2.2.0

set -euo pipefail

# ─────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIRMWARE_PATH="$ROOT_DIR/firmware/BrakeFlasher.ino"
CLI_BIN="arduino-cli"
BOARD_FQBN="arduino:avr:nano:cpu=atmega328old"
PORT_HINTS=("/dev/ttyUSB" "/dev/ttyACM" "/dev/cu.usbserial" "/dev/cu.wchusb" "COM")

echo "────────────────────────────────────────────────────────────"
echo "BOOTSTRAPPING FLASHING TOOLCHAIN"
echo "Firmware  : $FIRMWARE_PATH"
echo "Board     : $BOARD_FQBN"
echo "────────────────────────────────────────────────────────────"

# ─────────────────────────────────────────────────────────────
# Ensure arduino-cli is installed
# ─────────────────────────────────────────────────────────────
if ! command -v "$CLI_BIN" >/dev/null 2>&1; then
  echo "[!] arduino-cli not found – installing locally..."
  curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
  export PATH="$HOME/bin:$PATH"
fi

# ─────────────────────────────────────────────────────────────
# Ensure board platform is installed
# ─────────────────────────────────────────────────────────────
echo "[*] Updating core index..."
arduino-cli core update-index

if ! arduino-cli core list | grep -q "arduino:avr"; then
  echo "[*] Installing arduino:avr platform..."
  arduino-cli core install arduino:avr
fi

# ─────────────────────────────────────────────────────────────
# Validate firmware file
# ─────────────────────────────────────────────────────────────
if [ ! -f "$FIRMWARE_PATH" ]; then
  echo "ERROR: Missing firmware file: $FIRMWARE_PATH"
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# Detect serial port
# ─────────────────────────────────────────────────────────────
echo "[*] Scanning for serial devices..."
PORT=""

for hint in "${PORT_HINTS[@]}"; do
  candidates=$(ls ${hint}* 2>/dev/null || true)
  for port in $candidates; do
    PORT="$port"
    break 2
  done
done

if [[ -z "$PORT" ]]; then
  echo "[!] No serial ports detected. Please connect Arduino Nano and retry."
  exit 1
fi

echo "[✓] Detected device at: $PORT"

# ─────────────────────────────────────────────────────────────
# Prompt user to flash or exit
# ─────────────────────────────────────────────────────────────
echo
read -p "Flash firmware to device at $PORT now? [y/N] " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "[*] Flashing $FIRMWARE_PATH → $PORT"
  arduino-cli compile --fqbn "$BOARD_FQBN" "$FIRMWARE_PATH"
  arduino-cli upload -p "$PORT" --fqbn "$BOARD_FQBN" "$FIRMWARE_PATH"
  echo "[✓] Flash complete."
else
  echo "[*] Skipped flashing. Environment is ready."
fi
