#!/usr/bin/env bash
# File: scripts/build_release_docker.sh
# Purpose: Build and run the BrakeFlasher Toolkit release pipeline in Docker
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.1.0

set -euo pipefail

IMAGE_NAME="brakeflasher-release"
TAG="latest"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "------------------------------------------------------------"
echo "Building Docker Image: ${IMAGE_NAME}:${TAG}"
echo "------------------------------------------------------------"
docker build -t "${IMAGE_NAME}:${TAG}" "$ROOT_DIR"

echo "------------------------------------------------------------"
echo "Running BrakeFlasher Release Pipeline in Docker"
echo "------------------------------------------------------------"
docker run --rm \
  -v "$ROOT_DIR:/app" \
  -w /app \
  "${IMAGE_NAME}:${TAG}"

ZIP_PATH="$ROOT_DIR/release/brakeflasher_release.zip"
HASH_PATH="$ZIP_PATH.sha256"

if [[ -f "$ZIP_PATH" && -f "$HASH_PATH" ]]; then
  echo "------------------------------------------------------------"
  echo "Docker Release Completed Successfully"
  echo "Output ZIP:    $ZIP_PATH"
  echo "SHA256 Hash:   $(cut -d' ' -f1 "$HASH_PATH")"
  echo "------------------------------------------------------------"
  exit 0
else
  echo "[ERROR] Expected output not found: ZIP or SHA256 missing"
  exit 1
fi
