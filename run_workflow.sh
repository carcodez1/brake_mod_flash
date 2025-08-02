#!/usr/bin/env bash
set -euo pipefail

# === Load .env if exists ===
if [[ -f .env ]]; then
  echo "[INFO] Loading .env overrides..."
  set -a
  source .env
  set +a
fi

# === Required tools check ===
REQUIRED=("make" "arduino-cli" "docker")
for cmd in "${REQUIRED[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[ERROR] Required tool not found: $cmd"
    exit 1
  fi
done

# === Logging setup ===
mkdir -p release/logs
LOG="release/logs/makeflow_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

echo "[INFO] Starting BrakeFlasher OEM Makefile pipeline..."
echo "[INFO] Log file: $LOG"

# === Execute Makefile targets ===

echo "[STEP] Validating JSON schema..."
make validate-schema

echo "[STEP] Rendering firmware templates..."
make firmware-all

echo "[STEP] Compiling all patterns..."
make compile-all

echo "[STEP] Building GUI binary (PyInstaller)..."
make gui

echo "[STEP] Creating release metadata..."
make release-metadata

echo "[STEP] Generating fallback ZIPs..."
make fallback-zip

echo "[STEP] Creating docker release images..."
make docker-release

echo "[STEP] Final packaging..."
make zip

echo "[SUCCESS] All steps completed. Output is in /release/"

