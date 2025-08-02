#!/usr/bin/env bash
# File: scripts/docker_run_gui.sh
# Purpose: Launch BrakeFlasher GUI inside Docker with X11 support
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assigned
# Version: 1.0.0

set -euo pipefail

# Detect platform-specific DISPLAY setting
if grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
  export DISPLAY="$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0"
  export LIBGL_ALWAYS_INDIRECT=1
else
  export DISPLAY="${DISPLAY:-:0}"
fi

# Allow X11 access
xhost +local:docker &>/dev/null || true

# Run container with GUI access
docker run --rm \
  -e DISPLAY="$DISPLAY" \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "$(pwd)":/app \
  --name brake_gui \
  brake_gui
