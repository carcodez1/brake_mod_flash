#!/bin/bash
# File: run_all.sh
# Project: BRAKE_MOD_FLASH
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assigned
# Description: Hardened full build/test/package orchestrator for Linux/macOS/WSL2 environments

set -euo pipefail

# -------- CONFIG --------
PROJECT="BRAKE_MOD_FLASH"
VENV=".venv"
BUILD_DIR="build"
DIST_DIR="$BUILD_DIR/dist"
ARTIFACTS_DIR="$BUILD_DIR/artifacts"
EXE_NAME="BrakeFlasherEmulator"
SPEC_FILE="BrakeFlasherEmulator.spec"
LOG_FILE="$BUILD_DIR/build.log"
HEX_FILE="$ARTIFACTS_DIR/BrakeFlasher.hex"
TS=$(date +"%Y%m%d_%H%M%S")
ZIP_NAME="${PROJECT}_${TS}.zip"

REQUIRED_MODULES=(pyinstaller pytest pytest-cov mock)

# -------- ENV DETECTION --------
OS="$(uname -s)"
IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=true
fi

# -------- LOGGING --------
mkdir -p "$BUILD_DIR" "$DIST_DIR" "$ARTIFACTS_DIR"
: > "$LOG_FILE"

log() {
  echo "[*] $*" | tee -a "$LOG_FILE"
}
fatal() {
  echo "[✗] $*" | tee -a "$LOG_FILE" >&2
  exit 1
}

log "Starting build: $PROJECT"
log "OS Detected: $OS"
if $IS_WSL; then
  log "Running inside WSL environment"
fi

# -------- PYTHON + VENV --------
if ! command -v python3 &>/dev/null; then
  fatal "Python 3.7+ is required"
fi
PYTHON=python3

if [ ! -d "$VENV" ]; then
  log "Creating Python virtual environment..."
  $PYTHON -m venv "$VENV"
fi

# shellcheck disable=SC1090
source "$VENV/bin/activate"

log "Upgrading pip..."
pip install --upgrade pip >> "$LOG_FILE" 2>&1

log "Ensuring Python packages..."
for pkg in "${REQUIRED_MODULES[@]}"; do
  if ! python -c "import $pkg" &>/dev/null; then
    log "Installing $pkg..."
    pip install "$pkg" >> "$LOG_FILE" 2>&1 || fatal "Failed to install $pkg"
  else
    log "✓ $pkg present"
  fi
done

# -------- TEST RUN --------
log "Running tests..."
$PYTHON run_tests.py >> "$LOG_FILE" 2>&1 || fatal "Tests failed"
log "✓ Tests passed"

# -------- BUILD GUI --------
log "Building GUI binary with PyInstaller..."
pyinstaller --noconfirm "$SPEC_FILE" >> "$LOG_FILE" 2>&1 || fatal "PyInstaller build failed"

cp "dist/$EXE_NAME" "$DIST_DIR/" || fatal "$EXE_NAME not found in dist/"

# -------- COMPILE HEX OR STUB --------
if command -v arduino-cli &>/dev/null; then
  log "Compiling firmware to HEX..."
  arduino-cli compile --fqbn arduino:avr:uno firmware --output-dir "$ARTIFACTS_DIR" >> "$LOG_FILE" 2>&1
else
  log "arduino-cli not found. Writing HEX stub..."
  echo "// HEX STUB" > "$HEX_FILE"
fi

# -------- PACKAGE OUTPUT --------
log "Creating package ZIP: $ZIP_NAME"
zip -r "$BUILD_DIR/$ZIP_NAME" \
  "$DIST_DIR" "$ARTIFACTS_DIR" \
  firmware/metadata/*.json \
  scripts/*.py gui/*.py \
  "$SPEC_FILE" README.md LICENSE build_project.sh run_tests.py \
  >> "$LOG_FILE" 2>&1 || fatal "ZIP packaging failed"

log "✓ Build Complete:"
log "  - Package:     $BUILD_DIR/$ZIP_NAME"
log "  - GUI Binary:  $DIST_DIR/$EXE_NAME"
log "  - HEX Output:  $HEX_FILE"

if $IS_WSL; then
  WINPATH=$(wslpath -w "$BUILD_DIR/$ZIP_NAME")
  log "WSL Info: You can open the ZIP in Windows via:"
  echo "    explorer.exe \"$WINPATH\""
fi

exit 0
