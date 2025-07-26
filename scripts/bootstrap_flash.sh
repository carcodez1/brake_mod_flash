```bash
#!/usr/bin/env bash
# Brake Flasher Toolkit – Arduino CLI Setup + Auto Flash Utility
# Version: 1.2.0
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assignment
# Compatibility: macOS (Intel/Apple Silicon), Linux, WSL2, Git Bash (Windows)

set -euo pipefail

# ─────────────────────────────────────────────
# CONFIGURATION CONSTANTS
# ─────────────────────────────────────────────
CLI_URL="https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh"
CLI_BIN="$HOME/.local/bin/arduino-cli"
export PATH="$HOME/.local/bin:$PATH"
CORE_ID="arduino:avr"
BOARD_FQBN="arduino:avr:nano"
CONFIG_PATH="$HOME/.arduino15/arduino-cli.yaml"
FIRMWARE_FILE="firmware/BrakeFlasher.ino"
LOG_FILE="logs/flash.log"

DEFAULT_PORT_MAC="/dev/cu.usbserial"
DEFAULT_PORT_LINUX="/dev/ttyUSB0"
DEFAULT_PORT_WIN="COM3"

mkdir -p "$(dirname "$LOG_FILE")"

# ─────────────────────────────────────────────
# LOGGING HELPERS
# ─────────────────────────────────────────────
function timestamp() { date +"%Y-%m-%d %H:%M:%S"; }
function info()  { echo -e "[\033[1;34mINFO\033[0m]  $(timestamp)  $*" | tee -a "$LOG_FILE"; }
function warn()  { echo -e "[\033[1;33mWARN\033[0m]  $(timestamp)  $*" | tee -a "$LOG_FILE" >&2; }
function err()   { echo -e "[\033[1;31mFAIL\033[0m]  $(timestamp)  $*" | tee -a "$LOG_FILE" >&2; exit 1; }

# ─────────────────────────────────────────────
# PLATFORM DETECTION
# ─────────────────────────────────────────────
PLATFORM="unknown"
case "$(uname -s)" in
    Linux)
        if grep -qi microsoft /proc/version; then PLATFORM="wsl2"; else PLATFORM="linux"; fi ;;
    Darwin) PLATFORM="macos" ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
    *) PLATFORM="unsupported" ;;
esac
info "Detected platform: $PLATFORM"
[[ "$PLATFORM" == "unsupported" ]] && err "Unsupported shell environment. Aborting."

if [[ "$PLATFORM" == "wsl2" ]]; then
    warn "WSL2 detected. USB passthrough must be active (e.g., via usbipd-win)."
fi

# ─────────────────────────────────────────────
# ARDUINO-CLI INSTALL
# ─────────────────────────────────────────────
if ! command -v arduino-cli >/dev/null 2>&1; then
    info "arduino-cli not found. Installing from upstream..."
    mkdir -p ~/.local/bin
    curl -fsSL "$CLI_URL" | sh || err "Download failed – check your connection"
    chmod +x "$CLI_BIN"
    [[ -x "$CLI_BIN" ]] || err "CLI install failed"
    export PATH="$HOME/.local/bin:$PATH"
else
    CLI_LOC=$(command -v arduino-cli)
    info "arduino-cli located at: $CLI_LOC"
fi

# ─────────────────────────────────────────────
# CONFIG INIT (IDEMPOTENT)
# ─────────────────────────────────────────────
if [[ ! -f "$CONFIG_PATH" ]]; then
    info "Generating initial CLI config..."
    arduino-cli config init || warn "Config init failed – continuing"
else
    info "CLI config found: $CONFIG_PATH"
fi

# ─────────────────────────────────────────────
# CORE INSTALL / CHECK
# ─────────────────────────────────────────────
info "Updating core index..."
arduino-cli core update-index || warn "Core index update failed"

if ! arduino-cli core list | grep -q "$CORE_ID"; then
    info "Installing AVR core: $CORE_ID"
    arduino-cli core install "$CORE_ID" || err "Failed to install core: $CORE_ID"
else
    info "AVR core already installed: $CORE_ID"
fi

# ─────────────────────────────────────────────
# PORT AUTO-DETECT OR FALLBACK
# ─────────────────────────────────────────────
info "Detecting connected Arduino Nano..."
DETECTED_PORT=""
BOARD_LIST=$(arduino-cli board list | grep "$BOARD_FQBN" || true)

if [[ -n "$BOARD_LIST" ]]; then
    DETECTED_PORT=$(echo "$BOARD_LIST" | head -n1 | awk '{print $1}')
    info "Auto-detected port: $DETECTED_PORT"
else
    warn "No device auto-detected. Using fallback..."
    case "$PLATFORM" in
        macos)
            DETECTED_PORT=$(ls /dev/cu.usb* 2>/dev/null | head -n1 || echo "$DEFAULT_PORT_MAC") ;;
        linux|wsl2)
            DETECTED_PORT="$DEFAULT_PORT_LINUX" ;;
        windows)
            DETECTED_PORT="$DEFAULT_PORT_WIN" ;;
    esac
    if [[ "$PLATFORM" != "windows" && ! -e "$DETECTED_PORT" ]]; then
        warn "Fallback port $DETECTED_PORT not found on disk."
    fi
    info "Using fallback port: $DETECTED_PORT"
fi

# ─────────────────────────────────────────────
# VERIFY FIRMWARE PRESENCE
# ─────────────────────────────────────────────
if [[ ! -f "$FIRMWARE_FILE" ]]; then
    warn "Firmware missing: $FIRMWARE_FILE"
    warn "Run 'render_config_to_ino.py' to generate firmware."
    read -rp "[?] Skip flash and continue? [y/N]: " skip
    [[ "$skip" =~ ^[Yy]$ ]] && exit 0 || err "Aborting – firmware file required."
fi

# ─────────────────────────────────────────────
# FLASH PROMPT
# ─────────────────────────────────────────────
read -rp "[?] Flash firmware to $DETECTED_PORT now? [y/N]: " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    info "Flashing to $DETECTED_PORT..."
    arduino-cli upload -p "$DETECTED_PORT" --fqbn "$BOARD_FQBN" "$FIRMWARE_FILE" --verify --log-level info \
        && info "✅ Firmware uploaded and verified successfully." \
        || err "Upload failed. Check board connection or port."
else
    info "Upload skipped. Run 'make flash' manually later."
fi

# ─────────────────────────────────────────────
# FINAL SUMMARY
# ─────────────────────────────────────────────
echo ""
info "───────────── SETUP COMPLETE ─────────────"
info "Platform        : $PLATFORM"
info "CLI Version     : $(arduino-cli version | head -n1)"
info "Board FQBN      : $BOARD_FQBN"
info "Port Used       : $DETECTED_PORT"
info "Firmware File   : $FIRMWARE_FILE"
info "Log File        : $LOG_FILE"
info "Status          : OK"
echo ""

exit 0
```
