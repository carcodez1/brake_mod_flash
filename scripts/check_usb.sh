#!/usr/bin/env bash
# File: scripts/check_usb.sh
# Purpose: Validate USB port presence and permissions
set -euo pipefail

PORT="${PORT:-/dev/ttyUSB0}"

echo "[*] Checking for USB device at $PORT..."
if [ ! -e "$PORT" ]; then
  echo "[✗] ERROR: Device $PORT not found."
  exit 1
fi

if ! [ -r "$PORT" ] || ! [ -w "$PORT" ]; then
  echo "[✗] ERROR: Insufficient permissions on $PORT"
  echo "➜ Suggested fix: sudo usermod -aG dialout $USER && newgrp dialout"
  exit 1
fi

echo "[✓] USB device detected and accessible: $PORT"
