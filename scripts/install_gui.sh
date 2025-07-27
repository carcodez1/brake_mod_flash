#!/usr/bin/env bash
# File: scripts/install_gui.sh
# Purpose: Bootstrap GUI environment across Linux, macOS, and WSL2
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.1.0

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_BIN=${PYTHON_BIN:-"python3.11"}
VENV_DIR="$PROJECT_ROOT/.venv"
REQ_FILE="$PROJECT_ROOT/requirements.txt"
GUI_ENTRY="$PROJECT_ROOT/gui/emulator_gui.py"

echo "────────────────────────────────────────────────────────────"
echo "BOOTSTRAP: GUI ENVIRONMENT"
echo "Root        : $PROJECT_ROOT"
echo "Python      : $PYTHON_BIN"
echo "Venv Target : $VENV_DIR"
echo "────────────────────────────────────────────────────────────"

# Check Python
if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "ERROR: $PYTHON_BIN not found. Please install it or export PYTHON_BIN=/path/to/python"
  exit 1
fi

# Install system dependencies (Linux/WSL only)
OS_NAME=$(uname -s)
if [[ "$OS_NAME" == "Linux" ]]; then
  echo "[*] Checking tkinter (Linux/WSL)..."
  if ! "$PYTHON_BIN" -c "import tkinter" 2>/dev/null; then
    echo "[!] tkinter missing. Installing with apt..."
    sudo apt-get update -qq
    sudo apt-get install -y python3-tk
  fi
fi

# Install tkinter on macOS (warn only)
if [[ "$OS_NAME" == "Darwin" ]]; then
  echo "[*] macOS detected. Ensure Python is from python.org, not Homebrew."
  if ! "$PYTHON_BIN" -c "import tkinter" 2>/dev/null; then
    echo "[!] tkinter not found. Install Python from https://www.python.org/downloads/mac-osx/"
    exit 1
  fi
fi

# Create venv
if [ ! -d "$VENV_DIR" ]; then
  echo "[*] Creating virtual environment..."
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

# Activate and install deps
echo "[*] Installing dependencies..."
source "$VENV_DIR/bin/activate"
pip install --upgrade pip >/dev/null
pip install -r "$REQ_FILE"

# Confirm tkinter is functional in venv
if ! python -c "import tkinter" 2>/dev/null; then
  echo "[!] tkinter still not importable in virtual environment."
  echo "    Try installing system-wide or re-run with a different PYTHON_BIN."
  deactivate
  exit 1
fi

# Confirm emulator_gui.py exists
if [ ! -f "$GUI_ENTRY" ]; then
  echo "ERROR: GUI entry point not found at: $GUI_ENTRY"
  exit 1
fi

echo "────────────────────────────────────────────────────────────"
echo "GUI ENVIRONMENT READY"
echo "Activate manually: source .venv/bin/activate"
echo "Run GUI: python gui/emulator_gui.py"
echo "────────────────────────────────────────────────────────────"
