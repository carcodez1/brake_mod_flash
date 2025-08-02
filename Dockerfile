# SPDX-License-Identifier: Proprietary
# Toolkit: BrakeFlasher Toolkit (PLE)
# Version: 1.0.1
# Author: MyGeo LLC / jeff@jpgroup.tech
# License: NDA-only use – redistribution prohibited

FROM python:3.11-slim

LABEL maintainer="jeff@jpgroup.tech"
LABEL toolkit="BrakeFlasher Toolkit PLE"
LABEL version="1.0.1"
LABEL description="Enterprise Docker image for firmware/GUI/CLI generation and delivery"

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV DISPLAY=:0

# --- SYSTEM DEPS ---
RUN apt-get update && apt-get install -y \
    bash make curl zip unzip jq git ca-certificates \
    gcc-avr avr-libc avrdude \
    tk python3-tk python3-dev libx11-dev libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

# --- ARDUINO-CLI ---
RUN curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh && \
    mv ./bin/arduino-cli /usr/local/bin/arduino-cli && \
    arduino-cli config init --create && \
    arduino-cli core update-index && \
    arduino-cli core install arduino:avr

# --- WORKDIR + PROJECT ---
WORKDIR /app
COPY . /app

# --- PYTHON DEPS ---
RUN pip install --no-cache-dir -r requirements.txt

# --- OPTIONAL: Pre-cache GUI tkinter test ---
RUN python3 -c "import tkinter; print('tkinter OK')"

# --- GUI + CLI Entry Wrappers ---
COPY scripts/bootstrap_release.sh /usr/local/bin/start_release
COPY scripts/run_gui.sh /usr/local/bin/start_gui

RUN chmod +x /usr/local/bin/start_release /usr/local/bin/start_gui

# --- ENTRYPOINT ---
ENTRYPOINT ["bash"]
CMD ["start_release"]
