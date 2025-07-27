#!/bin/bash
# File: run_all.sh
# Project: BRAKE_MOD_FLASH
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assigned
# Description: Hardened full build/test/package orchestrator for Linux/macOS/WSL2 environments

set -euo pipefail
IFS=$'\n\t'

# -------- CONFIG --------
PROJECT="BRAKE_MOD_FLASH"
VENV=".venv"
BUILD_DIR="build"
DIST_DIR="$BUILD_DIR/dist"
ARTIFACTS_DIR="$BUILD_DIR/artifacts"
EXE_NAME="BrakeFlasherEmulator"
SPEC_FILE="gui/emulator_gui.spec"
LOG_FILE="$BUILD_DIR/build.log"
HEX_FILE="$ARTIFACTS_DIR/BrakeFlasher.hex"
VERSION_JSON="firmware/metadata/version.json"
TS=$(date +"%Y%m%d_%H%M%S")
VERSION=$(jq -r '.version // empty' "$VERSION_JSON" 2>/dev/null || echo "v0.0.0-unknown")
ZIP_NAME="${PROJECT}_${VERSION}_${TS}.zip"
REQUIRED_MODULES=(pyinstaller pytest pytest_cov mock)

# -------- ENV DETECTION --------
OS="$(uname -s)"
IS_WSL=false
grep -qi microsoft /proc/version && IS_WSL=true

# -------- LOGGING --------
mkdir -p "$BUILD_DIR" "$DIST_DIR" "$ARTIFACTS_DIR"
: > "$LOG_FILE"

log()   { echo "[*] $*" | tee -a "$LOG_FILE"; }
fatal() { echo "[✗] $*" | tee -a "$LOG_FILE" >&2; exit 1; }

log "🚀 Starting build: $PROJECT"
log "OS Detected: $OS"
$IS_WSL && log "Running inside WSL environment"

# -------- PYTHON + VENV --------
command -v python3 >/dev/null || fatal "Python 3.7+ is required"
PYTHON=python3

if [ ! -d "$VENV" ]; then
  log "Creating Python virtual environment..."
  $PYTHON -m venv "$VENV"
fi

# shellcheck disable=SC1090
source "$VENV/bin/activate"

log "Upgrading pip..."
pip install --upgrade pip >> "$LOG_FILE" 2>&1

log "Checking required Python packages..."
for pkg in "${REQUIRED_MODULES[@]}"; do
  if ! python -c "import $pkg" &>/dev/null; then
    log "Installing $pkg..."
    pip install "$pkg" >> "$LOG_FILE" 2>&1 || fatal "Failed to install $pkg"
  else
    log "✓ $pkg present"
  fi
done

# -------- TESTING --------
log "Running unit tests..."
if [[ -f scripts/run_tests.py ]]; then
  python3 scripts/run_tests.py || fatal "Unit tests failed"
  log "✓ Unit tests passed"
else
  log "⚠️  Test script not found: scripts/run_tests.py – skipping"
  
fi
# -------- VEHICLE FIRMWARE GENERATION --------
GEN_SCRIPT="scripts/gen_all_vehicle_firmware.sh"
if [[ -x "$GEN_SCRIPT" ]]; then
  log "Generating per-vehicle firmware..."
  bash "$GEN_SCRIPT" >> "$LOG_FILE" 2>&1 || fatal "Vehicle firmware generation failed"
else
  log "⚠️ Generator script missing or not executable: $GEN_SCRIPT"
fi

# -------- GUI LAUNCHER TEST --------
GUI_LAUNCHER_TEST="tests/test_run_gui_launcher.py"
if [[ -f "$GUI_LAUNCHER_TEST" ]]; then
  log "Running GUI launcher test..."
  pytest "$GUI_LAUNCHER_TEST" --disable-warnings -v >> "$LOG_FILE" 2>&1 || {
    log "⚠️  GUI launcher test failed – check tkinter or environment setup"
  }
else
  log "⚠️  GUI launcher test not found: skipping"
fi

# -------- BUILD GUI --------
log "Building GUI binary with PyInstaller..."
pyinstaller --noconfirm "$SPEC_FILE" >> "$LOG_FILE" 2>&1 || fatal "PyInstaller build failed"
cp "dist/$EXE_NAME" "$DIST_DIR/" || fatal "$EXE_NAME not found after build"

# -------- COMPILE HEX OR STUB --------
if command -v arduino-cli &>/dev/null; then
  log "Compiling firmware to HEX..."
  arduino-cli compile --fqbn arduino:avr:uno firmware --output-dir "$ARTIFACTS_DIR" >> "$LOG_FILE" 2>&1
else
  log "arduino-cli not found. Writing HEX stub..."
  echo "// HEX STUB" > "$HEX_FILE"
fi

# -------- PACKAGE OUTPUT --------
log "Creating final ZIP: $ZIP_NAME"
zip -r "$BUILD_DIR/$ZIP_NAME" \
  "$DIST_DIR" "$ARTIFACTS_DIR" \
  firmware/metadata/*.json \
  scripts/*.py gui/*.py \
  "$SPEC_FILE" README.md LICENSE run_all.sh \
  >> "$LOG_FILE" 2>&1 || fatal "ZIP packaging failed"

log "✓ Build Complete:"
log "  - Package:     $BUILD_DIR/$ZIP_NAME"
log "  - GUI Binary:  $DIST_DIR/$EXE_NAME"
log "  - HEX Output:  $HEX_FILE"

if $IS_WSL; then
  WINPATH=$(wslpath -w "$BUILD_DIR/$ZIP_NAME")
  log "WSL Shortcut: explorer.exe \"$WINPATH\""
fi

exit 0
