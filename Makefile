# Makefile – Brake Light Flasher Toolkit (Enterprise-Grade PLE)
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assignment
# Version: 2.4.0

.SHELLFLAGS := -euo pipefail -c

PYTHON = python3
ARDUINO_CLI = arduino-cli
SRC_DIR = firmware/sources
BIN_DIR = firmware/binaries
META_DIR = firmware/metadata
META_CUSTOMER = $(META_DIR)/per_customer
CONFIG_DIR = config/vehicles
TEMPLATE = firmware/templates/BrakeFlasher.ino.j2
SCHEMA = config/schema/flash_pattern.schema.json
GEN_SCRIPT = scripts/render_config_to_ino.py
TEST_SCRIPT = scripts/gen_test_assets.py
VERSION_FILE = $(META_DIR)/version.json
OUTPUT_ZIP = release/brakeflasher_release.zip
RELEASE_MANIFEST = release/manifest.json

DEFAULT_VEHICLE = hyundai_sonata_2020
DEFAULT_INO = $(SRC_DIR)/$(DEFAULT_VEHICLE).ino
DEFAULT_HEX = $(BIN_DIR)/$(DEFAULT_VEHICLE).hex

PORT ?= $(shell ls /dev/ttyUSB* 2>/dev/null | head -n1)
GIT_TAG = $(shell git describe --tags --always 2>/dev/null || echo "no-tag")

.PHONY: all clean firmware compile flash test test-assets zip coverage docs help hash version flash-all test-full test-short gui run-gui package validate-schema \
        build release package-summary sign docker-gui docker-release ci-test release-metadata

## all: Run full release pipeline (build, test, zip, sign, metadata)
all: release

## build: Generate firmware and binaries (no test or zip)
build: clean test-assets firmware-all compile-all

## release: Full build → test → zip → hash → sign → manifest → summary
release: build test-full zip hash sign release-metadata package-summary

## help: Display this help message
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

clean:
	@echo "[•] Cleaning generated files..."
	@rm -rf $(SRC_DIR)/*.ino $(BIN_DIR)/*.hex $(META_DIR)/*.json \
		$(META_CUSTOMER)/*.json .pytest_cache coverage.xml htmlcov \
		release/*.zip release/*.sig release/*.json || true

## firmware: Render firmware for the default vehicle
firmware:
	@echo "[•] Rendering firmware for default vehicle..."
	@mkdir -p $(SRC_DIR) $(META_DIR)
	$(PYTHON) $(GEN_SCRIPT) \
		--input $(CONFIG_DIR)/$(DEFAULT_VEHICLE).json \
		--template $(TEMPLATE) \
		--output $(DEFAULT_INO) \
		--meta $(META_DIR)/$(DEFAULT_VEHICLE).json \
		--schema $(SCHEMA)

## firmware-all: Render firmware for all configured vehicles
firmware-all:
	@echo "[•] Rendering firmware for all vehicles..."
	@mkdir -p $(SRC_DIR) $(META_CUSTOMER)
	@for config in $(CONFIG_DIR)/*.json; do \
		name=$$(basename $$config .json); \
		echo "[•] Rendering: $$name"; \
		$(PYTHON) $(GEN_SCRIPT) \
			--input $$config \
			--template $(TEMPLATE) \
			--output $(SRC_DIR)/$$name.ino \
			--meta $(META_CUSTOMER)/$$name.json \
			--schema $(SCHEMA); \
	done

## compile: Compile the default .ino file
compile:
	@echo "[•] Compiling default firmware..."
	@mkdir -p $(BIN_DIR)
	@if [ ! -f $(DEFAULT_INO) ]; then echo "[✗] Missing INO: $(DEFAULT_INO)"; exit 1; fi
	$(ARDUINO_CLI) compile \
		--fqbn arduino:avr:nano \
		--output-dir $(BIN_DIR) $(DEFAULT_INO)

## compile-all: Compile all .ino files to .hex
compile-all:
	@echo "[•] Compiling all firmware sources..."
	@mkdir -p $(BIN_DIR)
	@if [ -z "$$(ls -1 $(SRC_DIR)/*.ino 2>/dev/null)" ]; then echo "[✗] No .ino files found in $(SRC_DIR)"; exit 1; fi
	@for ino in $(SRC_DIR)/*.ino; do \
		echo "[•] Compiling: $$ino"; \
		$(ARDUINO_CLI) compile \
			--fqbn arduino:avr:nano \
			--output-dir $(BIN_DIR) $$ino; \
	done

## flash: Upload the default .hex file to Arduino
flash:
	@echo "[•] Uploading firmware to Arduino on PORT: $(PORT)"
	@if [ -z "$(PORT)" ]; then echo "[✗] No USB device found"; exit 1; fi
	$(ARDUINO_CLI) upload \
		--fqbn arduino:avr:nano \
		--port $(PORT) \
		--input-dir $(BIN_DIR) \
		--input-file $(DEFAULT_HEX)

## flash-all: Upload all compiled .hex files sequentially
flash-all:
	@echo "[•] Flashing ALL .hex files on PORT: $(PORT)"
	@if [ -z "$(PORT)" ]; then echo "[✗] No USB device found"; exit 1; fi
	@for hex in $(BIN_DIR)/*.hex; do \
		echo "[•] Flashing: $$hex"; \
		$(ARDUINO_CLI) upload \
			--fqbn arduino:avr:nano \
			--port $(PORT) \
			--input-dir $(BIN_DIR) \
			--input-file $$hex; \
	done

## test-assets: Generate vehicle test input configs
test-assets:
	@echo "[•] Generating test JSON configs..."
	@$(PYTHON) $(TEST_SCRIPT)

## test: Run short test suite
test: test-short

## test-short: Run minimal, fast test checks
test-short:
	@echo "[•] Running short test suite..."
	pytest tests --tb=short --disable-warnings --maxfail=1 -x --strict-markers

## test-full: Run full suite with coverage reports
test-full:
	@echo "[•] Running full test suite with coverage..."
	pytest tests --cov=scripts --cov-report=term --cov-report=html --strict-markers

## ci-test: Run tests in CI-friendly format (no color)
ci-test:
	@echo "[•] Running tests (CI mode)..."
	pytest tests --cov=scripts --cov-report=term-missing --color=no --strict-markers

## coverage: Generate local HTML code coverage
coverage:
	@echo "[•] Generating HTML coverage..."
	pytest tests --cov=scripts --cov-report=html

## validate-schema: Validate all configs with JSON schema
validate-schema:
	@echo "[•] Validating all JSON configs against schema..."
	@for config in $(CONFIG_DIR)/*.json; do \
		echo " → Validating: $$config"; \
		$(PYTHON) -m jsonschema --instance $$config --schema $(SCHEMA); \
	done

## zip: Package deliverables into release ZIP
zip:
	@echo "[•] Packaging delivery ZIP..."
	@mkdir -p release
	@zip -r $(OUTPUT_ZIP) \
		$(SRC_DIR) $(BIN_DIR) $(META_DIR) \
		gui logs README.md LICENSE Makefile \
		firmware/templates/ config/schema/ config/vehicles/

## hash: Create SHA256 checksum of release
hash:
	@echo "[•] SHA256 hash of release ZIP:"
	@sha256sum $(OUTPUT_ZIP) | tee $(OUTPUT_ZIP).sha256

## sign: GPG sign the release ZIP (detached)
sign:
	@echo "[•] Signing release ZIP with GPG..."
	@gpg --output $(OUTPUT_ZIP).sig --detach-sign $(OUTPUT_ZIP)

## version: Show toolkit version (from metadata)
version:
	@echo "[•] Toolkit Version:"
	@jq -r .version $(VERSION_FILE)

## docs: View README in pager
docs:
	@less README.md

## gui: Build GUI binary using PyInstaller
gui:
	@echo "[•] Building GUI executable..."
	@./build_gui.sh

## run-gui: Launch the emulator GUI
run-gui:
	@echo "[•] Launching Emulator GUI..."
	@$(PYTHON) gui/emulator_gui.py

## docker-gui: Run GUI in Docker Compose
docker-gui:
	@echo "[*] Running GUI in Docker..."
	@docker compose -f docker-compose.gui.yml up --build

## docker-release: Run release pipeline in Docker
docker-release:
	@echo "[*] Running full build in Docker (non-GUI)..."
	@docker build -t brake_release .
	@docker run --rm -v $(PWD):/app brake_release

## release-metadata: Generate JSON manifest for release
release-metadata:
	@echo "[•] Writing release metadata..."
	@mkdir -p release
	@echo '{' > $(RELEASE_MANIFEST)
	@echo '  "version": "'$$(jq -r .version $(VERSION_FILE))'",' >> $(RELEASE_MANIFEST)
	@echo '  "git_tag": "$(GIT_TAG)",' >> $(RELEASE_MANIFEST)
	@echo '  "build_time": "'$$(date -Iseconds)'",' >> $(RELEASE_MANIFEST)
	@echo '  "vehicle_count": '$$(ls $(CONFIG_DIR)/*.json | wc -l) >> $(RELEASE_MANIFEST)
	@echo '}' >> $(RELEASE_MANIFEST)

## package-summary: Show final release summary
package-summary:
	@echo ""
	@echo "===Brake Flasher Toolkit Release Summary ==="
	@echo "Version:         $$(jq -r .version $(VERSION_FILE))"
	@echo "Git Tag:         $(GIT_TAG)"
	@echo "Build Time:      $$(date -Iseconds)"
	@echo "Vehicles Built:  $$(ls $(SRC_DIR)/*.ino | wc -l)"
	@echo "Release Output:  $(OUTPUT_ZIP)"
	@echo "SHA256:          $$(cut -d ' ' -f 1 $(OUTPUT_ZIP).sha256)"
	@echo ""
