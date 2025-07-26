# Makefile – Brake Light Flasher Toolkit (Enterprise Grade – PLE)
# Version: 1.2.3
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assignment
# Platforms: Windows (Git Bash / WSL2), macOS (Intel/Apple Silicon), Linux (Debian/Ubuntu)

# ----------------------------------------------------------------------
# PLATFORM-AWARE PYTHON ENV
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

# ----------------------------------------------------------------------
# DEFINITIONS
VENV_DIR := .venv
GUI_SCRIPT := gui/emulator_gui.py
FIRMWARE_SCRIPT := scripts/render_config_to_ino.py
PYI_SPEC := gui/BrakeFLashEmulator.spec
OUTPUT_DIR := dist
FIRMWARE_OUT := firmware/BrakeFlasher.ino
HASH_OUT := firmware/metadata/firmware_hash.txt
FINAL_ZIP := output/BrakeFlasher_PRO_v1.2.3.zip

# ----------------------------------------------------------------------
# FULL BUILD CHAIN
all: install-deps gui firmware package checksum zip

# ----------------------------------------------------------------------
# VENV SETUP
venv:
	@uname -a || ver
	@if [ ! -d "$(VENV_DIR)" ]; then \
		$(PYTHON) -m venv $(VENV_DIR); \
	fi
	@echo "Virtual environment ready."

# ----------------------------------------------------------------------
# DEPENDENCY INSTALL
install-deps: venv
	@echo "[*] Installing required packages..."
	@$(PIP) install --upgrade pip
	@$(PIP) install -r requirements.txt jinja2 pyinstaller
	@echo "[✓] Dependencies ready."

# ----------------------------------------------------------------------
# GUI EMULATOR
gui:
	@$(PY) $(GUI_SCRIPT)

# ----------------------------------------------------------------------
# RENDER .INO FROM CONFIG
firmware:
	@echo "[*] Rendering firmware..."
	@$(PY) $(FIRMWARE_SCRIPT)
	@if [ ! -f "$(FIRMWARE_OUT)" ]; then echo "[✗] Firmware generation failed."; exit 1; fi
	@echo "[✓] Firmware: $(FIRMWARE_OUT)"

# ----------------------------------------------------------------------
# COMPILE GUI
package:
	@echo "[*] Building GUI binary..."
	@mkdir -p $(OUTPUT_DIR)
	@$(PY) -m PyInstaller $(PYI_SPEC) || { echo "[✗] PyInstaller failed."; exit 1; }
	@if [ ! -f "$(OUTPUT_DIR)/BrakeFLashEmulator" ] && [ ! -f "$(OUTPUT_DIR)/BrakeFLashEmulator.exe" ]; then \
		echo "[✗] Build failed. Binary not found."; exit 1; fi
	@echo "[✓] GUI binary created."

# ----------------------------------------------------------------------
# GENERATE CHECKSUM
checksum:
	@echo "[*] Computing SHA256 hash..."
	@mkdir -p firmware/metadata
	@$(PY) -c "import hashlib; f=open('$(FIRMWARE_OUT)','rb'); print(hashlib.sha256(f.read()).hexdigest())" > $(HASH_OUT)
	@echo "[✓] Hash saved: $(HASH_OUT)"

# ----------------------------------------------------------------------
# TEST SUITE
test:
	@$(PY) -m pytest --cov=.

# ----------------------------------------------------------------------
# CLEAN ALL
clean:
	@echo "[*] Cleaning artifacts..."
	@rm -rf .venv build dist __pycache__ .pytest_cache
	@rm -rf gui/__pycache__ gui/state/*
	@rm -f logs/*.log
	@rm -f firmware/*.ino firmware/metadata/*.json
	@echo "[✓] Clean complete."

# ----------------------------------------------------------------------
# FULL REBUILD
rebuild: clean all

# ----------------------------------------------------------------------
# FLASH TO ARDUINO
flash:
	@command -v arduino-cli >/dev/null || (echo "[✗] arduino-cli not found. Run: bash scripts/bootstrap_flash.sh" && exit 127)
	@echo "[*] Flashing Arduino Nano..."
	arduino-cli upload -p /dev/ttyUSB0 --fqbn arduino:avr:nano firmware/BrakeFlasher.ino --verify --log-level info \
	|| (echo "[✗] Flash failed – check USB/port/board." && exit 1)

# ----------------------------------------------------------------------
# CREATE FINAL ZIP
zip:
	@mkdir -p output
	@zip -r $(FINAL_ZIP) firmware gui docs config scripts run_all.* LICENSE requirements.txt
	@echo "[✓] ZIP created: $(FINAL_ZIP)"

# ----------------------------------------------------------------------
# DELIVERY STAGE
delivery: zip
	@echo ""
	@echo "Delivery Artifact:"
	@echo "  Archive: $(FINAL_ZIP)"
	@echo "  Contents: firmware, GUI, config, docs, scripts"
	@echo "  Delivery via: Notion, secure email, or direct upload"
	@echo "[✓] Delivery complete."

# ----------------------------------------------------------------------
# VEHICLE-SPECIFIC BUILD
vehicle:
	@mkdir -p firmware/binaries firmware/metadata/per_customer/$(CUSTOMER)
	@$(PY) scripts/render_config_to_ino.py \
		--input config/vehicles/$(VEHICLE).json \
		--template templates/BrakeFlasher.ino.j2 \
		--output firmware/binaries/$(VEHICLE).ino \
		--meta firmware/metadata/per_customer/$(CUSTOMER)/firmware_version.json \
		--board $(BOARD) \
		--customer_id $(CUSTOMER)

# ----------------------------------------------------------------------
# RENDER ALL VEHICLES
render-all:
	@for v in kia_optima_2019 nissan_altima_2021 hyundai_elantra_2018 kia_sorento_2022 genesis_g80_2023; do \
		make vehicle VEHICLE=$$v CUSTOMER=cust_$$v BOARD=nano; \
	done

# ----------------------------------------------------------------------
# HELP MENU
help:
	@echo ""
	@echo "Brake Light Flasher Toolkit – PLE Makefile Targets"
	@echo "--------------------------------------------------"
	@echo "  make venv          - Setup Python virtualenv"
	@echo "  make install-deps  - Install dependencies"
	@echo "  make gui           - Run GUI emulator"
	@echo "  make firmware      - Render .ino firmware"
	@echo "  make package       - Build GUI binary"
	@echo "  make checksum      - Hash firmware"
	@echo "  make flash         - Flash Arduino Nano"
	@echo "  make zip           - Package delivery ZIP"
	@echo "  make delivery      - Full delivery pipeline"
	@echo "  make test          - Run unit tests"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make rebuild       - Rebuild entire project"
	@echo "  make vehicle       - Build per-vehicle (VEHICLE, CUSTOMER, BOARD)"
	@echo "  make render-all    - Build all preset vehicles"
	@echo "  make help          - Show this help menu"
	@echo ""

.PHONY: all venv install-deps gui firmware package checksum test clean rebuild flash zip delivery vehicle render-all help
