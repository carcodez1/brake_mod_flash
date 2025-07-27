# Makefile – Brake Light Flasher Toolkit (Enterprise Grade – PLE)
# Version: 1.2.6
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assignment
# Platforms: Windows (Git Bash / WSL2), macOS (Intel/Apple Silicon), Linux (Debian/Ubuntu)

# ──────────────────────────────────────────────────────────────
# PLATFORM-AWARE ENVIRONMENT
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

# ──────────────────────────────────────────────────────────────
# GLOBAL VARIABLES
VENV_DIR := .venv
GUI_SCRIPT := gui/emulator_gui.py
FIRMWARE_SCRIPT := scripts/render_config_to_ino.py
PYI_SPEC := gui/emulator_gui.spec
OUTPUT_DIR := dist
FIRMWARE_OUT := firmware/BrakeFlasher.ino
HASH_OUT := firmware/metadata/firmware_hash.txt
FINAL_ZIP := output/BrakeFlasher_PRO_v1.2.6.zip
VERSION_FILE := firmware/metadata/firmware_version.json

# ──────────────────────────────────────────────────────────────
# FULL BUILD PIPELINE
all: install-deps gui firmware package checksum zip

# ──────────────────────────────────────────────────────────────
# VIRTUAL ENVIRONMENT
venv:
	@uname -a || ver
	@if [ ! -d "$(VENV_DIR)" ]; then \
		$(PYTHON) -m venv $(VENV_DIR); \
	fi
	@echo "[✓] Virtual environment ready."

# ──────────────────────────────────────────────────────────────
# DEPENDENCIES
install-deps: venv
	@echo "[*] Installing required packages..."
	@$(PIP) install --upgrade pip
	@$(PIP) install -r requirements.txt
	@echo "[✓] Dependencies ready."

# ──────────────────────────────────────────────────────────────
# GUI EMULATOR – LAUNCH
gui:
	@echo "[*] Bootstrapping Emulator GUI..."
	@bash scripts/install_gui.sh

# ──────────────────────────────────────────────────────────────
# RENDER INO FROM CONFIG
firmware:
	@echo "[*] Rendering firmware..."
	@$(PY) $(FIRMWARE_SCRIPT)
	@if [ ! -f "$(FIRMWARE_OUT)" ]; then echo "[✗] Firmware generation failed."; exit 1; fi
	@echo "[✓] Firmware generated: $(FIRMWARE_OUT)"

# ──────────────────────────────────────────────────────────────
# COMPILE GUI BINARY
package:
	@echo "[*] Building GUI binary..."
	@mkdir -p $(OUTPUT_DIR)
	@$(PY) -m PyInstaller $(PYI_SPEC) --noconfirm
	@if [ ! -f "$(OUTPUT_DIR)/BrakeFlashEmulator" ] && [ ! -f "$(OUTPUT_DIR)/BrakeFlashEmulator.exe" ]; then \
		echo "[✗] Binary not found."; exit 1; fi
	@echo "[✓] GUI binary built."

# ──────────────────────────────────────────────────────────────
# FIRMWARE CHECKSUM
checksum:
	@echo "[*] Generating SHA256..."
	@mkdir -p firmware/metadata
	@$(PY) -c "import hashlib; f=open('$(FIRMWARE_OUT)','rb'); print(hashlib.sha256(f.read()).hexdigest())" > $(HASH_OUT)
	@echo "[✓] Hash saved: $(HASH_OUT)"

# ──────────────────────────────────────────────────────────────
# TEST SUITE
test:
	@$(PY) -m pytest --cov=.

# ──────────────────────────────────────────────────────────────
# CLEAN BUILD ARTIFACTS
clean:
	@echo "[*] Cleaning build artifacts..."
	@rm -rf $(VENV_DIR) build dist __pycache__ .pytest_cache
	@rm -rf gui/__pycache__ gui/state/*
	@rm -f logs/*.log
	@rm -f firmware/*.ino firmware/metadata/*.json
	@echo "[✓] Clean complete."

# ──────────────────────────────────────────────────────────────
# FULL REBUILD
rebuild: clean all

# ──────────────────────────────────────────────────────────────
# FLASH ARDUINO DEVICE
flash:
	@command -v arduino-cli >/dev/null || (echo "[✗] arduino-cli not found. Run: bash scripts/bootstrap_flash.sh" && exit 127)
	@echo "[*] Flashing to Arduino Nano..."
	arduino-cli upload -p /dev/ttyUSB0 --fqbn arduino:avr:nano firmware/BrakeFlasher.ino --verify --log-level info || \
	(echo "[✗] Flash failed – check board and port." && exit 1)

# ──────────────────────────────────────────────────────────────
# PACKAGE PROJECT
zip:
	@mkdir -p output
	@zip -r $(FINAL_ZIP) firmware gui docs config scripts run_all.* LICENSE requirements.txt
	@echo "[✓] Package ready: $(FINAL_ZIP)"

# ──────────────────────────────────────────────────────────────
# DELIVERY
delivery: zip
	@echo ""
	@echo "Delivery Complete:"
	@echo "  ▶ ZIP: $(FINAL_ZIP)"
	@echo "  ▶ Contents: firmware, GUI, config, scripts"
	@echo "  ▶ Transfer: Notion / secure email / file portal"

# ──────────────────────────────────────────────────────────────
# VEHICLE-SPECIFIC BUILD
vehicle:
	@mkdir -p firmware/binaries firmware/metadata/per_customer/$(CUSTOMER)
	@$(PY) $(FIRMWARE_SCRIPT) \
		--input config/vehicles/$(VEHICLE).json \
		--template templates/BrakeFlasher.ino.j2 \
		--output firmware/binaries/$(VEHICLE).ino \
		--meta firmware/metadata/per_customer/$(CUSTOMER)/firmware_version.json \
		--board $(BOARD) \
		--customer_id $(CUSTOMER)

# ──────────────────────────────────────────────────────────────
# RENDER ALL VEHICLE BINARIES
render-all:
	@for v in kia_optima_2019 nissan_altima_2021 hyundai_elantra_2018 kia_sorento_2022 genesis_g80_2023; do \
		make vehicle VEHICLE=$$v CUSTOMER=cust_$$v BOARD=nano; \
	done

# ──────────────────────────────────────────────────────────────
# USAGE
help:
	@echo ""
	@echo "Brake Flasher Toolkit – Makefile Targets"
	@echo "──────────────────────────────────────────"
	@echo "  make venv          – Setup virtualenv"
	@echo "  make install-deps  – Install Python deps"
	@echo "  make gui           – Run GUI emulator"
	@echo "  make firmware      – Generate .ino firmware"
	@echo "  make package       – Build GUI binary"
	@echo "  make checksum      – Generate SHA256"
	@echo "  make flash         – Flash Arduino"
	@echo "  make zip           – Build delivery ZIP"
	@echo "  make delivery      – Delivery summary"
	@echo "  make test          – Run unit tests"
	@echo "  make clean         – Cleanup project"
	@echo "  make rebuild       – Full rebuild"
	@echo "  make vehicle       – Build vehicle config (VEHICLE, CUSTOMER, BOARD)"
	@echo "  make render-all    – Build all supported vehicles"
	@echo "  make help          – Show this menu"
	@echo ""

.PHONY: all venv install-deps gui firmware package checksum test clean rebuild flash zip delivery vehicle render-all help


