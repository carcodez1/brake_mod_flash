#!/usr/bin/env bash
# File: scripts/launch_emulator.sh
# Purpose: Launch the BrakeFlasher GUI emulator with headless fallback
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.0.0

set -euo pipefail

# Ensure script is executed from project root
cd "$(dirname "$0")/.."

# Path to emulator
EMU_PATH="gui/emulator_gui.py"

if [[ ! -f "$EMU_PATH" ]]; then
  echo "[✗] ERROR: Emulator not found at $EMU_PATH"
  exit 1
fi

# Auto-fallback to xvfb if DISPLAY is unset
if [[ -z "${DISPLAY:-}" ]]; then
  echo "[*] DISPLAY not set – launching emulator via xvfb-run"
  xvfb-run -a python3 "$EMU_PATH"
else
  echo "[*] DISPLAY detected: $DISPLAY – launching emulator"
  python3 "$EMU_PATH"
fi
