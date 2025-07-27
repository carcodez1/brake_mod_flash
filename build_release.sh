#!/bin/bash
# File: scripts/build_release.sh
# Author: Jeffrey Plewak
# Version: v1.0.1
# Purpose: Hardened release packager for BrakeFlasher PRO
# License: Proprietary – NDA/IP Assignment

set -euo pipefail
IFS=$'\n\t'

VERSION="v1.0.1"
OUTDIR="output"
METADIR="firmware/metadata"
ZIPFILE="${OUTDIR}/BrakeFlasher_PRO_${VERSION}.zip"
MANIFEST="${METADIR}/sha256_manifest.txt"
TEST_SCRIPT="scripts/run_tests.py"

echo "────────────────────────────────────────────────────────────"
echo "🔧 [1/6] Preparing directories..."
mkdir -p "$OUTDIR" "$METADIR"

echo "🧹 [2/6] Cleaning old artifacts..."
rm -f "$ZIPFILE" "$MANIFEST"

echo "🧪 [3/6] Running test suite..."
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
  ! -name "*.pyc" \
  ! -path "*/__pycache__/*" \
  -exec sha256sum {} \; | sort > "$MANIFEST"

echo "📦 [5/6] Creating ZIP archive: $ZIPFILE"
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

echo "🔐 [6/6] Verifying archive integrity and recording hash..."
sha256sum "$ZIPFILE" >> "$MANIFEST"
unzip -t "$ZIPFILE" > /dev/null

echo "✅ Build complete: $ZIPFILE"
echo "📜 Manifest saved: $MANIFEST"
echo "────────────────────────────────────────────────────────────"
