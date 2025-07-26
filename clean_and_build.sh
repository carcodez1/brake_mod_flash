#!/usr/bin/env bash

# clean_and_build_gui.sh
# Cleans build artifacts and rebuilds BrakeFlasher GUI with correct PyYAML handling
# Author: Jeffrey Plewak
# Version: 1.0.1

set -euo pipefail

echo "[*] Cleaning old build artifacts..."
rm -rf build/ dist/ __pycache__/
find . -name '*.spec' -delete
find . -name '*.pyc' -delete
find . -name '*.pyo' -delete
find . -type d -name '__pycache__' -exec rm -rf {} +

echo "[*] Validating YAML import..."
if grep -q "import pyyaml" gui/emulator_gui.py; then
  echo "[✗] ERROR: Invalid import 'import pyyaml' found. Removing..."
  sed -i.bak '/import pyyaml/d' gui/emulator_gui.py
  rm -f gui/emulator_gui.py.bak
  echo "[✓] Fixed invalid import."
else
  echo "[✓] YAML import is clean."
fi

echo "[*] Rebuilding GUI binary with PyInstaller..."
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

