#!/usr/bin/env bash
# File: scripts/bootstrap-release.sh
# Purpose: Hardened full release pipeline with validation and reporting
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.1.0

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RELEASE_ZIP="release/brakeflasher_release.zip"
HASH_FILE="${RELEASE_ZIP}.sha256"

function log() {
  printf "[%s] %s\n" "$(date +'%H:%M:%S')" "$1"
}

function section() {
  echo -e "\n────────────────────────────────────────────────────────────"
  echo "🔧 $1"
  echo "────────────────────────────────────────────────────────────"
}

function verify_output() {
  [[ -f "$RELEASE_ZIP" ]] || { echo "[✗] ZIP not found: $RELEASE_ZIP"; exit 1; }
  [[ -f "$HASH_FILE" ]] || { echo "[✗] SHA256 file not found: $HASH_FILE"; exit 1; }

  EXPECTED=$(cut -d ' ' -f1 < "$HASH_FILE")
  ACTUAL=$(sha256sum "$RELEASE_ZIP" | cut -d ' ' -f1)

  if [[ "$EXPECTED" != "$ACTUAL" ]]; then
    echo "[✗] SHA256 mismatch:"
    echo "    Expected: $EXPECTED"
    echo "    Actual:   $ACTUAL"
    exit 1
  fi
}

section "Validating Environment"
[[ -f Makefile ]] || { echo "[✗] Makefile not found in $ROOT_DIR"; exit 1; }
command -v make >/dev/null || { echo "[✗] make not found"; exit 1; }
command -v python3 >/dev/null || { echo "[✗] python3 not found"; exit 1; }
command -v arduino-cli >/dev/null || { echo "[✗] arduino-cli not found"; exit 1; }

section "Cleaning Old Builds"
log "Running: make clean"
make clean

section "Generating Test Assets"
log "Running: make test-assets"
make test-assets

section "Rendering All Firmware"
log "Running: make firmware-all"
make firmware-all

section "Compiling All Firmware"
log "Running: make compile-all"
make compile-all

section "Running Full Test Suite"
log "Running: make test-full"
make test-full

section "Packaging Release ZIP"
log "Running: make zip"
make zip

section "Generating SHA256 Hash"
log "Running: make hash"
make hash

section "Verifying Output Integrity"
verify_output

section "Release Complete"
echo "✅ Release ready: $RELEASE_ZIP"
echo "🔐 SHA256 hash:  $HASH_FILE"
echo "📁 Includes:     sources/, binaries/, metadata/, gui/, logs/"
echo "🧪 Test Status:  PASS"
echo "🏁 Timestamp:     $(date -Iseconds)"
echo "────────────────────────────────────────────────────────────"
