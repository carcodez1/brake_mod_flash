#!/bin/bash
# File: scripts/bootstrap_gui.sh
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Description: Hardened GUI bootstrapper that uses the best available Python,
# verifies tkinter, installs dependencies, and prevents version mismatch.

set -euo pipefail
IFS=$'\n\t'

echo "────────────────────────────────────────────"
echo "🛠  Bootstrapping GUI Environment (Cross-Platform)"
echo "────────────────────────────────────────────"

VENV_DIR=".venv"
REQUIREMENTS="requirements.txt"
GUI_SCRIPT="gui/emulator_gui.py"

# Auto-select best available Python (3.11 preferred)
detect_python() {
  for candidate in python3.11 python3.10 python3.9 python3.8; do
    if command -v "$candidate" >/dev/null 2>&1; then
      echo "$candidate"
      return
    fi
  done
  echo "[✗] No suitable Python 3.8+ interpreter found." >&2
  exit 127
}

PYTHON=$(detect_python)
echo "[✓] Using Python: $PYTHON"

# Verify tkinter is importable via system Python
echo "[*] Checking tkinter availability..."
if ! "$PYTHON" -c "import tkinter" 2>/dev/null; then
  echo "[✗] tkinter missing – attempting install..."
  if command -v apt >/dev/null; then
    sudo apt update
    sudo apt install -y python3-tk
  else
    echo "[✗] Unsupported package manager – please install tkinter manually." >&2
    exit 1
  fi
  if ! "$PYTHON" -c "import tkinter" 2>/dev/null; then
    echo "[✗] tkinter still not available – aborting." >&2
    exit 1
  fi
fi

echo "[✓] tkinter verified in system Python"

# Wipe and recreate venv with system site-packages for tkinter passthrough
echo "[*] Rebuilding virtual environment with system site-packages..."
rm -rf "$VENV_DIR"
"$PYTHON" -m venv "$VENV_DIR" --system-site-packages
source "$VENV_DIR/bin/activate"

# Hardened pip installation
echo "[*] Installing pip packages..."
pip install --upgrade pip
pip install -r "$REQUIREMENTS" pyinstaller

# Verify tkinter inside venv
echo "[*] Verifying tkinter in virtual environment..."
if ! python -c "import tkinter" 2>/dev/null; then
  echo "[✗] tkinter NOT found in virtualenv – retrying with PYTHONPATH fallback..."
  PYTHONPATH="/usr/lib/python3/dist-packages" python -c "import tkinter" || {
    echo "[✗] tkinter still unavailable – aborting." >&2
    exit 1
  }
fi

echo "────────────────────────────────────────────"
echo "[✓] GUI environment is fully ready."
echo "To launch emulator: make gui"
echo "────────────────────────────────────────────"
