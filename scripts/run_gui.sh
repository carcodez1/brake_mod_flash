#!/usr/bin/env bash
# File: scripts/run_gui.sh
# Purpose: Launch the Brake Flasher Emulator GUI inside a virtual environment
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.0.0

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_PATH="$ROOT_DIR/.venv"
GUI_PATH="$ROOT_DIR/gui/emulator_gui.py"

echo "────────────────────────────────────────────────────────────"
echo "LAUNCHING EMULATOR GUI"
echo "Root        : $ROOT_DIR"
echo "Python Venv : $VENV_PATH"
echo "GUI Path    : $GUI_PATH"
echo "────────────────────────────────────────────────────────────"

if [ ! -f "$GUI_PATH" ]; then
  echo "ERROR: GUI script not found at $GUI_PATH"
  exit 1
fi

if [ ! -f "$VENV_PATH/bin/activate" ]; then
  echo "ERROR: Virtual environment not found."
  echo "Run: bash scripts/install_gui.sh"
  exit 1
fi

source "$VENV_PATH/bin/activate"

echo "[*] Activating virtual environment..."
python "$GUI_PATH"
