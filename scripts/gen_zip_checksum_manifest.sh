#!/usr/bin/env bash
# File: scripts/gen_zip_checksum_manifest.sh
# Purpose: Generate sha256sums.txt inside each unzipped firmware output folder
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assignment

set -euo pipefail

OUTPUT_DIR="output"
ZIP_DIR="$OUTPUT_DIR/zips"

echo "──────────────────────────────────────────────"
echo "CHECKSUM: GENERATE sha256sums.txt"
echo "Output ZIP Dir : $ZIP_DIR"
echo "──────────────────────────────────────────────"

total=0
updated=0
fail=0

for zipfile in "$ZIP_DIR"/*.zip; do
  ((total++))
  tempdir=$(mktemp -d)
  name=$(basename "$zipfile" .zip)

  unzip -q "$zipfile" -d "$tempdir"

  if ! command -v sha256sum &>/dev/null; then
    echo "[✗] sha256sum not available"
    exit 1
  fi

  pushd "$tempdir" >/dev/null
  sha256sum * > sha256sums.txt
  zip -q -j "$zipfile" sha256sums.txt
  popd >/dev/null
  rm -rf "$tempdir"

  echo "  [✓] Updated: $name.zip"
  ((updated++))
done

echo "──────────────────────────────────────────────"
echo "SUMMARY"
echo "ZIPs Found      : $total"
echo "Updated ZIPs    : $updated"
echo "──────────────────────────────────────────────"
