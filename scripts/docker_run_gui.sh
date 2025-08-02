#!/usr/bin/env bash
# Launch GUI manually using docker (non-compose)

set -euo pipefail
export DISPLAY=${DISPLAY:-:0}
xhost +local:root

docker run --rm \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "$(pwd)":/app \
  --name brake_gui \
  brake_gui
