#!/usr/bin/env bash
# File: scripts/setup_gui_docker_support.sh
# Purpose: Patch existing Dockerfile and add GUI docker-compose for BrakeFlasher Toolkit
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assigned
# Version: 1.0.0

set -euo pipefail

DOCKERFILE="Dockerfile"
COMPOSE_FILE="docker-compose.gui.yml"

echo "[*] Backing up $DOCKERFILE to $DOCKERFILE.bak"
cp "$DOCKERFILE" "$DOCKERFILE.bak"

echo "[*] Patching $DOCKERFILE for GUI support..."
awk '
/^# SYSTEM SETUP/ {
  print "# SYSTEM SETUP + GUI support"
  print "RUN apt-get update && apt-get install -y \\"
  print "    curl zip unzip jq make git bash \\"
  print "    python3-tk tk libx11-dev x11-apps \\"
  print "    && rm -rf /var/lib/apt/lists/*"
  skip=1; next
}
/^RUN apt-get update && apt-get install -y/ && skip {next}
{print}
' "$DOCKERFILE.bak" > "$DOCKERFILE"

echo "[*] Appending CMD for GUI override..."
grep -q "CMD \[\"python3\", \"gui/emulator_gui.py\"\]" "$DOCKERFILE" || echo 'CMD ["python3", "gui/emulator_gui.py"]' >> "$DOCKERFILE"

echo "[✓] Dockerfile patched successfully."

echo "[*] Creating $COMPOSE_FILE..."
cat > "$COMPOSE_FILE" <<EOF
version: "3.8"
services:
  brake_gui:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      DISPLAY: "\${DISPLAY}"
    volumes:
      - .:/app
      - /tmp/.X11-unix:/tmp/.X11-unix
    command: ["python3", "gui/emulator_gui.py"]
EOF

echo "[✓] Created $COMPOSE_FILE"

echo "[✓] GUI Docker support setup complete."
echo "To run the GUI: docker compose -f $COMPOSE_FILE up --build"
