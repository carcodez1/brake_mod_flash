#!/usr/bin/env bash
# File: scripts/fix_fallback_config.sh
# Purpose: Replace JSON-LD fallback config with valid emulator schema

set -euo pipefail

mkdir -p gui/config

TARGET="gui/config/default_fallback.json"

cat > "$TARGET" <<EOF
{
  "version": "1.0.0",
  "pattern": [
    { "count": 3, "on": 100, "off": 100 },
    { "count": 2, "on": 200, "off": 200 },
    { "count": 1, "on": 400, "off": 400 }
  ],
  "metadata": {
    "config_id": "default-flash-v1",
    "legal_notice": "Proprietary – NDA / IP Assigned",
    "source": "fallback"
  }
}
EOF

echo "[✓] Config patched: $TARGET"
