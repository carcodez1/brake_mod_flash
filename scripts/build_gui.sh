#!/usr/bin/env bash
# File: scripts/build_gui.sh
# Purpose: Build BrakeFlasher GUI using PyInstaller
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assignment

set -euo pipefail

ROOT_DIR="$(dirname "$(realpath "$0")")/.."
SPEC_FILE="$ROOT_DIR/gui/emulator_gui.spec"

cd "$ROOT_DIR"
echo "[*] Building BrakeFlasher GUI with PyInstaller..."

pyinstaller "$SPEC_FILE"

if [[ -f dist/BrakeFlashEmulator || -f dist/BrakeFlashEmulator.exe ]]; then
  echo "[✓] GUI binary built successfully."
else
  echo "[✗] GUI binary not found. Build failed." >&2
  exit 1
fi
