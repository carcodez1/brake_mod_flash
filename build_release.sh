
#!/bin/bash
# build_release.sh - Final hardened release builder for BrakeFlasher PRO v1.0.1
# Author: Jeffrey Plewak
# Purpose: Local, silent, cross-platform-safe release packaging

set -euo pipefail

VERSION="v1.0.1"
OUTDIR="output"
METADIR="firmware/metadata"
ZIPFILE="${OUTDIR}/BrakeFlasher_PRO_${VERSION}.zip"
MANIFEST="${METADIR}/sha256_manifest.txt"
TEST_SCRIPT="scripts/run_tests.py"

echo "────────────────────────────────────────────────────────────"
echo "🔧 [1/6] Preparing directories..."
mkdir -p "$OUTDIR"
mkdir -p "$METADIR"

echo "🧹 [2/6] Cleaning old artifacts..."
rm -f "$ZIPFILE" "$MANIFEST"

echo "🧪 [3/6] Running tests..."
if [[ -f "$TEST_SCRIPT" ]]; then
    python3 "$TEST_SCRIPT" || { echo "✗ Tests failed. Aborting."; exit 1; }
else
    echo "⚠️  Warning: Test script '$TEST_SCRIPT' not found. Skipping tests."
fi

echo "🧾 [4/6] Generating SHA256 manifest..."
find . \
  -type f \
  ! -path "./.git/*" \
  ! -path "./tests/*" \
  ! -path "./output/*" \
  ! -name "*.DS_Store" \
  -exec sha256sum {} \; | sort > "$MANIFEST"

echo "📦 [5/6] Creating ZIP archive..."
zip -r "$ZIPFILE" \
  build/ \
  config/ \
  docs/ \
  firmware/ \
  gui/ \
  logs/ \
  scripts/ \
  run_all.sh \
  run_all.bat \
  LICENSE \
  -x "*.DS_Store" "*.pyc" "__pycache__/*" ".git/*" "tests/*"

echo "🔐 [6/6] Verifying ZIP and recording hash..."
sha256sum "$ZIPFILE" >> "$MANIFEST"
unzip -t "$ZIPFILE" > /dev/null

echo "✅ Build complete: $ZIPFILE"
echo "📜 Manifest saved: $MANIFEST"
echo "────────────────────────────────────────────────────────────"
