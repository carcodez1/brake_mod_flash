#!/bin/bash
# File: build_gui.sh
# Author: Jeffrey Plewak
# Purpose: Build standalone GUI binary for BrakeFlasher PRO using PyInstaller
# License: Proprietary – NDA / IP Assigned
# Version: 1.0.1

set -euo pipefail
IFS=$'\n\t'

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────
SCRIPT_NAME="emulator_gui.py"
ENTRY_POINT="gui/${SCRIPT_NAME}"
DIST_DIR="dist"
BUILD_DIR="build"
SPEC_FILE="BrakeFLashEmulator.spec"
EXE_NAME="BrakeFLashEmulator"
ICON_PATH="gui/assets/icon.ico"
VENV_DIR=".venv"

#───────────────────────────────────────────────────────────────────────────────
# FUNCTIONS
#───────────────────────────────────────────────────────────────────────────────

abort() {
  echo "[✗] $1" >&2
  exit 1
}

log() {
  echo "[*] $1"
}

check_pyinstaller() {
  log "Checking for PyInstaller..."
  if ! command -v pyinstaller >/dev/null; then
    abort "PyInstaller not found. Activate venv and install: pip install pyinstaller"
  fi
  log "[✓] PyInstaller found: $(pyinstaller --version)"
}

check_entry() {
  [[ -f "$ENTRY_POINT" ]] || abort "Entry script not found: $ENTRY_POINT"
}

check_icon() {
  if [[ ! -f "$ICON_PATH" ]]; then
    log "Warning: Icon not found at $ICON_PATH – generating fallback"
    mkdir -p "$(dirname "$ICON_PATH")"
    if command -v convert >/dev/null; then
      convert -size 1x1 xc:none "$ICON_PATH"
      log "[✓] Created fallback transparent icon"
    else
      echo -ne '\x00' > "$ICON_PATH"
      log "[✓] Binary fallback icon created"
    fi
  fi
}

clean_previous_build() {
  log "Cleaning previous builds..."
  rm -rf "$DIST_DIR" "$BUILD_DIR" __pycache__ *.spec
}

build_with_spec() {
  if [[ -f "$SPEC_FILE" ]]; then
    log "Using existing spec file: $SPEC_FILE"
    pyinstaller "$SPEC_FILE" --noconfirm --clean
  else
    log "No spec file found – generating fresh build"
    pyinstaller "$ENTRY_POINT" \
      --noconfirm --clean --onefile \
      --name "$EXE_NAME" \
      --icon="$ICON_PATH" \
      --distpath "$DIST_DIR" \
      --workpath "$BUILD_DIR" \
      --log-level=WARN
  fi
}

verify_output() {
  BIN="$DIST_DIR/$EXE_NAME"
  [[ -f "$BIN" ]] || abort "Build failed: $BIN not found"
  chmod +x "$BIN"
  log "[✓] GUI binary built successfully: $BIN"
}

print_summary() {
  echo "────────────────────────────────────────────"
  echo "✅ GUI Build Complete"
  echo "📦 Binary: $DIST_DIR/$EXE_NAME"
  echo "📁 Build:  $BUILD_DIR"
  echo "🔧 Icon:   $ICON_PATH"
  echo "────────────────────────────────────────────"
}

#───────────────────────────────────────────────────────────────────────────────
# EXECUTION
#───────────────────────────────────────────────────────────────────────────────

echo "────────────────────────────────────────────"
echo "🚧 Building GUI: $EXE_NAME"
echo "────────────────────────────────────────────"

check_pyinstaller
check_entry
check_icon
clean_previous_build
build_with_spec
verify_output
print_summary

