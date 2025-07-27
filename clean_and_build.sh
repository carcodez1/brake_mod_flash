#!/usr/bin/env bash
# File: scripts/clean_and_build_gui.sh
# Author: Jeffrey Plewak
# Version: 1.0.1
# Purpose: Clean and rebuild BrakeFlasher GUI safely with PyInstaller + YAML check
# License: Proprietary – NDA/IP Assignment

set -euo pipefail
IFS=$'\n\t'

echo "────────────────────────────────────────────"
echo "🧹 Cleaning old GUI build artifacts..."
rm -rf build/ dist/ __pycache__/ .pytest_cache/
find . -name '*.spec' -delete
find . -name '*.pyc' -delete
find . -name '*.pyo' -delete
find . -type d -name '__pycache__' -exec rm -rf {} +

echo "🔍 Validating YAML import statement..."
if grep -q "import pyyaml" gui/emulator_gui.py; then
  echo "[✗] Invalid import: 'import pyyaml' found – patching..."
  sed -i.bak '/import pyyaml/d' gui/emulator_gui.py
  rm -f gui/emulator_gui.py.bak
  echo "[✓] Removed incorrect PyYAML import."
else
  echo "[✓] No invalid 'pyyaml' import found."
fi

echo "🛠  Rebuilding GUI binary with PyInstaller..."
pyinstaller gui/emulator_gui.py \
  --onefile \
  --noconfirm \
  --clean \
  --name=BrakeFLashEmulator \
  --hidden-import=yaml \
  --icon=gui/assets/icon.ico

echo "────────────────────────────────────────────"
echo "✅ GUI Build Complete"
echo "📦 Binary: dist/BrakeFLashEmulator"
echo "📁 Build:  build/"
echo "🔧 Icon:   gui/assets/icon.ico"
echo "────────────────────────────────────────────"
