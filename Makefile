# Makefile – Brake Light Flasher Toolkit (Enterprise Grade)
# Version: 1.2.3
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assignment
# Targets: Windows (Git Bash / WSL2), macOS (Intel/Apple Silicon), Linux (Debian/Ubuntu)

ifeq ($(OS),Windows_NT)
	PYTHON := python
	PIP := .venv/Scripts/pip.exe
	PY := .venv/Scripts/python.exe
	SHELL := cmd
else
	PYTHON := python3
	PIP := .venv/bin/pip
	PY := .venv/bin/python
	SHELL := /bin/bash
endif

# Paths and filenames
VENV_DIR := .venv
GUI_SCRIPT := gui/emulator_gui.py
FIRMWARE_SCRIPT := scripts/render_config_to_ino.py
PYI_SPEC := gui/BrakeFLashEmulator.spec
OUTPUT_DIR := dist
FIRMWARE_OUT := firmware/BrakeFlasher.ino
METADATA_OUT := firmware/metadata/firmware_version.json
HASH_OUT := firmware/metadata/firmware_hash.txt
FINAL_ZIP := output/BrakeFlasher_PRO_v1.2.3.zip

# ----------------------------------------------------------------------
# Complete Build Pipeline
all: install-deps gui firmware package checksum zip

# ----------------------------------------------------------------------
# Virtual Environment Setup
venv:
	@uname -a || ver
	@if [ ! -d "$(VENV_DIR)" ]; then \
		$(PYTHON) -m venv $(VENV_DIR); \
	fi
	@echo "Virtual environment is ready."

# ----------------------------------------------------------------------
# Dependency Installation
install-deps: venv
	@echo "Installing required Python packages..."
	@$(PIP) install --upgrade pip
	@$(PIP) install -r requirements.txt pyinstaller
	@echo "Dependencies installation complete."

# ----------------------------------------------------------------------
# Launch Emulator GUI
gui:
	@$(PY) $(GUI_SCRIPT)

# ----------------------------------------------------------------------
# Generate Firmware (.ino) from Config
firmware:
	@echo "Generating Arduino firmware from config..."
	@$(PY) $(FIRMWARE_SCRIPT)
	@if [ ! -f "$(FIRMWARE_OUT)" ]; then echo "Firmware generation failed. Missing: $(FIRMWARE_OUT)"; exit 1; fi
	@echo "Firmware output: $(FIRMWARE_OUT)"

# ----------------------------------------------------------------------
# Build GUI Executable with PyInstaller
package:
	@echo "Compiling GUI binary..."
	@mkdir -p $(OUTPUT_DIR)
	@if ! command -v $(PY) > /dev/null; then \
		echo "Python interpreter not found."; exit 1; \
	fi
	@$(PY) -m PyInstaller $(PYI_SPEC) || { echo "PyInstaller build failed."; exit 1; }
	@if [ ! -f "$(OUTPUT_DIR)/BrakeFLashEmulator" ] && [ ! -f "$(OUTPUT_DIR)/BrakeFLashEmulator.exe" ]; then \
		echo "Binary output not found after build."; exit 1; \
	fi
	@echo "GUI binary successfully created in $(OUTPUT_DIR)/"

# ----------------------------------------------------------------------
# SHA256 Hashing of Firmware Output
checksum:
	@echo "Computing firmware SHA256 hash..."
	@mkdir -p firmware/metadata
	@$(PY) -c "import hashlib; f=open('$(FIRMWARE_OUT)','rb'); print(hashlib.sha256(f.read()).hexdigest())" > $(HASH_OUT)
	@echo "Hash saved to: $(HASH_OUT)"

# ----------------------------------------------------------------------
# Run Unit Tests
test:
	@$(PY) -m pytest --cov=.

# ----------------------------------------------------------------------
# Clean All Build Artifacts
clean:
	@echo "[*] Cleaning build environment..."
	@deactivate 2>/dev/null || true
	@rm -rf .venv build dist __pycache__ .pytest_cache
	@rm -rf gui/__pycache__ gui/state/*
	@rm -f logs/flash.log
	@rm -f firmware/*.ino firmware/metadata/*.json
	@echo "[✓] Clean complete."

# ----------------------------------------------------------------------
# Full Rebuild from Scratch
rebuild: clean all

# ----------------------------------------------------------------------
# Upload Firmware to Arduino Nano
# Ensure CLI is installed before flashing
flash:
	@command -v arduino-cli >/dev/null || (echo "[✗] arduino-cli not found. Run: bash scripts/bootstrap_flash.sh" && exit 127)
	@echo "[*] Flashing firmware to Arduino Nano..."
	arduino-cli upload -p /dev/ttyUSB0 --fqbn arduino:avr:nano firmware/BrakeFlasher.ino --verify --log-level info \
	|| (echo "[✗] Upload failed – check board, port, or firmware" && exit 1)

# ----------------------------------------------------------------------
# Archive Final Delivery Package
zip:
	@mkdir -p output
	@zip -r $(FINAL_ZIP) firmware gui docs config scripts run_all.* LICENSE requirements.txt
	@echo "ZIP archive created at: $(FINAL_ZIP)"

# ----------------------------------------------------------------------
# Delivery Confirmation Output
delivery: zip
	@echo ""
	@echo "Final Delivery Artifact:"
	@echo "  Archive Path: $(FINAL_ZIP)"
	@echo "  Contents: firmware, GUI, config, docs, scripts, install files"
	@echo "  Transfer Method: Notion, secure email, or customer upload"
	@echo "Delivery build is complete."

# ----------------------------------------------------------------------
# Display Help
help:
	@echo ""
	@echo "Brake Light Flasher Toolkit – Makefile Targets"
	@echo "--------------------------------------------------"
	@echo "  make venv         - Create virtual environment"
	@echo "  make install-deps - Install dependencies"
	@echo "  make gui          - Launch emulator GUI"
	@echo "  make firmware     - Generate Arduino .ino file"
	@echo "  make package      - Build GUI binary (PyInstaller)"
	@echo "  make checksum     - Generate SHA256 of firmware"
	@echo "  make flash        - Upload firmware to Arduino Nano"
	@echo "  make zip          - Create delivery ZIP package"
	@echo "  make delivery     - Full archive for client delivery"
	@echo "  make test         - Run tests with coverage"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make rebuild      - Clean and rebuild everything"
	@echo "  make help         - Display this help menu"
	@echo ""

.PHONY: all venv install-deps gui firmware package checksum test clean rebuild flash zip delivery help
