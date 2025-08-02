BrakeFlasher Toolkit – Professional Distribution Package
Version: 1.0.1
Build Timestamp: 2025-07-26T00:00:00Z
Principal Engineer: Jeffrey Plewak
Contact: carcodez1@gmail.com
License: Proprietary – NDA + IP Assignment Enforced
Jurisdiction: United States (North Carolina)
Target Vehicles: Hyundai / Kia – Third Brake Light (Center High-Mount Stop Lamp)
Hardware: Arduino Nano (ATmega328P, 5V, 16MHz)
Firmware Interface: Input Pin D3 (active HIGH), Output Pin D4 (MOSFET-driven)

==============================================================================

INTRODUCTION

This toolkit delivers a production-grade, legally auditable system for retrofitting Hyundai and Kia vehicles with a programmable third brake light. It enables compliance-aligned safety enhancements while preserving factory-revertibility.

Every firmware build, configuration file, GUI interaction, and log is hashed, version-controlled, and compliant with evidentiary standards. The system is modular, scriptable, GUI-operable, and packaged for installers, auditors, and resale scenarios.

This is not a prototype. It is a hardened, enterprise-distributable system engineered for repeatable installs, technical validation, and DOT/NCGS fallback requirements.

==============================================================================

SYSTEM OBJECTIVES

1. Provide enhanced visibility brake light logic compliant with U.S. DOT (FMVSS 108)
2. Enable GUI + JSON control over flashing sequence, timing, and pattern lifecycle
3. Embed audit-grade version metadata in every output (firmware, config, manifest)
4. Enable full rollback and hash-based integrity verification
5. Support legal compliance in North Carolina and U.S. jurisdictions via PDF/A-3-ready metadata
6. Package installer-ready ZIP bundles for field install, audit, and resale
7. Prepare for optional feature overlays (NFC tag pairing, VIN-locking, static QR trace, X.509 signing)

==============================================================================

INSTALLATION PATHWAYS

Option A: One-line Installer (Silent Mode)
------------------------------------------
Windows:
    run_all.bat

Linux/macOS:
    bash run_all.sh

Behavior:
- Sets up virtual environment if not present
- Validates dependencies (PyYAML, tkinter, arduino-cli)
- Launches GUI in silent mode with default config
- Renders INO + metadata + SHA256 manifest
- Uploads firmware to connected Arduino Nano
- Logs all actions to logs/flashlog.txt

Option B: Manual CLI Execution
------------------------------
1. Launch GUI:
       python gui/emulator_gui.py

2. Modify or load preset pattern
3. Save JSON → gui/state/last_config.json
4. Render firmware:
       python scripts/render_config_to_ino.py

5. Compile:
       arduino-cli compile --fqbn arduino:avr:nano firmware/BrakeFlasher.ino

6. Upload to Nano:
       arduino-cli upload -p /dev/ttyUSB0 --fqbn arduino:avr:nano firmware/BrakeFlasher.ino

Logs, configs, and outputs will be written to:
- logs/flashlog.txt
- firmware/
- output/
- sha256_manifest.txt

==============================================================================

FLASHING PATTERN: DEFAULT SEQUENCE

• 3 × Quick Flash   (100ms ON / 100ms OFF)
• 2 × Medium Flash  (200ms ON / 200ms OFF)
• 1 × Slow Flash    (400ms ON / 400ms OFF)
• Solid Hold        (until brake released)

Pattern is customizable via:
- config/flash_settings.json
- gui/config_template.json
- GUI emulator (live preview/editable)

==============================================================================

DIRECTORY MAP (EXHAUSTIVE)

gui/                 → GUI Emulator, config state, pattern presets
config/              → Default and custom flash timing JSONs
firmware/            → Generated INO, metadata JSON, compiled HEX
scripts/             → CLI tools: renderer, uploader, validator, diagnostics
logs/                → Timestamped flash traces and build events
output/              → Versioned delivery ZIPs (installer-ready)
tests/               → pytest-compatible coverage for core modules
docs/                → Mermaid diagrams, legal compliance maps, glossary
Makefile             → Automation targets for: gui, firmware, flash, test, package
run_all.sh           → macOS/Linux automation entrypoint
run_all.bat          → Windows automation entrypoint
sha256_manifest.txt  → Rolling hash manifest for all critical outputs

==============================================================================

ROLLBACK PROCEDURE (VERSION-CONTROLLED)

To revert to a prior firmware configuration:
1. Identify desired INO or HEX version from output/ archive
2. Restore matching gui/config_template.json snapshot
3. Run render_config_to_ino.py to regenerate firmware
4. Validate with sha256_manifest.txt
5. Flash via bootstrap_flash.sh or Arduino CLI

All rollback states are cryptographically linked to build metadata for audit compliance.

==============================================================================

VERSIONING STRATEGY

Each delivery ZIP includes:
- firmware/BrakeFlasher.ino and firmware.hex
- gui/config_template.json snapshot
- firmware/metadata/firmware_version.json
- sha256_manifest.txt (all files)
- flashlog.txt (timestamped)
- output/brake_flasher_v1.0.1.zip (auto-named)
- docs/*.mmd (Mermaid diagrams)
- LICENSE.txt, README.txt, CHANGELOG.txt

Version ID: timestamp-based or semantic (configurable)  
Build Hash: SHA256 of rendered firmware, config, and metadata

==============================================================================

TESTING (UNIT + SCHEMA)

To run full suite:
    make test

Validates:
- JSON schema against flash_settings.json
- Pattern logic and durations
- Renderer consistency across scenarios
- Checksum generation
- Metadata correctness
- GUI interface stability under common presets

Outputs:
- Terminal pass/fail trace
- HTML coverage report → coverage_html/index.html

Test Count: 24  
Initial Coverage: 93%

==============================================================================

SAFETY GUIDANCE AND HARDWARE INTERFACE

- Never wire Arduino D4 directly to 12V lighting circuit
- Use a logic-level MOSFET or opto-isolated relay rated for 12V @ 2A+
- Include a fuse in-line with power input to prevent shorts
- Test outputs with a multimeter or oscilloscope before in-vehicle install
- Confirm vehicle brake signal logic (active-high vs sinking)
- Mount Arduino Nano securely using non-conductive fasteners

==============================================================================

OPTIONAL ENTERPRISE FEATURES (DISABLED BY DEFAULT)

These features are scaffolded and visible in GUI or metadata, but inactive unless enabled at build time:

- VIN Lock: restricts firmware execution to one VIN via config fingerprinting
- NFC Tag Integration: embeds certificate hash in paired NFC tag
- Static QR Trace: encodes firmware hash + issuance URL as static QR
- X.509 Digital Signature: applies cryptographic signature to firmware and metadata
- PDF/A-3 Export: generates signed, court-admissible PDF certificate with firmware trace
- Multi-Device Flash Mode: allows batch flashing of multiple units from one CLI session

Enterprise builds require key provisioning and external configuration from MyGeo LLC.

==============================================================================

LEGAL COMPLIANCE

- FMVSS 108: Solid fallback mode guarantees federal lighting compliance
- NCGS Ch. 66: Digital signatures and audit logs permitted in commerce
- NCGS Ch. 8: Admissibility of hashed electronic records
- NCGS Ch. 1A, Rule 43: Supports electronic evidence and traceable installs

Outputs include:
- Timestamped metadata
- Embedded SHA256 checksums
- Court-admissible config trail (fallback.zip available)
- Optional PDF/A-3 and NFC delivery format (enterprise)

==============================================================================

MERMAID DIAGRAMS

docs/flow.mmd         → Pattern → Renderer → INO Flow
docs/structure.mmd    → Directory layout + dependencies
docs/compliance.mmd   → Legal metadata trace, 7DP schema

Render using: mermaid.live or VSCode Mermaid Preview

==============================================================================

SUPPORT AND CONTACT

Primary Contact: Jeffrey Plewak  
Email: carcodez1@gmail.com  
Response SLA: ≤ 24 hours (U.S. Eastern)

Delivery Options:
- GitHub ZIP download (release page)
- Secure signed ZIP via email
- USB delivery (on request)
- Offline fallback kit (enterprise only)

Enterprise Licensing: MyGeo LLC (contact for terms and provisioning)

==============================================================================

CONCLUSION

The BrakeFlasher Toolkit is a production-intent system that merges embedded safety firmware with legal-grade traceability. Every artifact — firmware, configuration, logs, diagrams — is independently verifiable and suitable for court, installer, or auditor presentation.

This toolkit is ready for certified delivery, resale, and field deployment.

END OF README
