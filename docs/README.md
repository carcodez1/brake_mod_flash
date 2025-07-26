BrakeFlasher Toolkit – Professional Distribution Package  
Version: 1.0.1  
Build Timestamp: 2025-07-26T00:00:00Z  
Principal Engineer: Jeffrey Plewak  
Contact: carcodez1@gmail.com  
License: Proprietary – NDA + IP Assignment Enforced  
Target: Hyundai / Kia – Third Brake Light (Center High-Mount Stop Lamp)  
Hardware: Arduino Nano (ATmega328P, 5V, 16MHz)

------------------------------------------------------------------------------

INTRODUCTION

This toolkit enables a professional-grade, legally reviewable modification of a vehicle's third brake light using a configurable flashing firmware. Built around the Arduino Nano, the system transforms the brake signal into a safety-enhancing visual pattern, increasing visibility and reaction time while preserving full revertibility to factory settings.

It is engineered for compliance, traceability, and ease of use. Every component – firmware, configuration, logs, and metadata – is structured, versioned, hashed, and independently verifiable. A GUI tool and command-line automation are included to support both technical and non-technical users.

This is not a prototype. It is a hardened, production-capable delivery intended for field installation, resale, audit, and future trace.

------------------------------------------------------------------------------

SYSTEM OBJECTIVES

1. Deliver a safe, field-tested brake light behavior pattern  
2. Support customizable timing sequences with full firmware regeneration  
3. Maintain complete audit trail via versioned JSON + SHA256 hash  
4. Provide GUI, CLI, and one-line installation pathways  
5. Ensure legal reversibility and DOT fallback compliance  
6. Package all deliverables for third-party installers and customers

------------------------------------------------------------------------------

User
 │
 │ Launch GUI
 ▼
╔════════════════════════════╗
║ BrakeFlashEmulator (Tkinter GUI) ║
╚════════════════════════════╝
        │
        ├─▶ [Input Flash Pattern] ─┐
        │                          │
        ├─▶ [Save Config JSON] ◀───┘
        │       │
        │       ├─▶ gui/config_template.json
        │       └─▶ gui/state/last_config.json
        │
        ├─▶ [Export YAML] ──────▶ gui/export.yaml (optional)
        │
        ├─▶ [Load Preset] ──────▶ gui/state/presets/*.json
        │
        ├─▶ [Preview Metadata] ─▶ reads config_template.json
        │
        ├─▶ [Run Renderer] ──────┐
        │                        │
        │                        ▼
        │           render_config_to_ino.py
        │                 │
        │                 ├─▶ Reads: gui/config_template.json
        │                 ├─▶ Generates: firmware/BrakeFlasher.ino
        │                 └─▶ Metadata: firmware/metadata/firmware_version.json
        │
        └─▶ [Run bootstrap_flash.sh]
                            │
                            ├─▶ Detects OS and arduino-cli
                            ├─▶ Validates .ino + USB port
                            └─▶ Uploads via: arduino-cli upload ...
                                     │
                                     ▼
                           Arduino Nano (ATmega328P)
                                     │
                                     └─▶ Flashes Brake Light with Pattern



7DP STRUCTURED PROVENANCE

Who     : Jeffrey Plewak (Engineer), Project Stakeholder (NDA-bound)  
What    : Flasher firmware, configuration GUI, generator scripts, logs, metadata  
When    : Built and tagged 2025-07-26T00:00:00Z (UTC)  
Where   : United States – Targeting deployment in North Carolina (NCGS jurisdiction)  
Why     : Increase braking visibility, reduce rear-end collision risk  
Which   : Input: D3 (5V logic), Output: D4 (MOSFET-driven); Arduino Nano, 5V/16MHz  
How     : JSON config → firmware generator → .ino → compiled and flashed firmware

------------------------------------------------------------------------------

FEATURES

- Arduino Nano firmware (ATmega328P, 5V, 16MHz)
- Configurable flashing sequences (GUI or JSON)
- Silent install: `run_all.sh` / `run_all.bat`
- Full SHA256 hashing for firmware validation
- Firmware versioning + embedded build metadata
- Mermaid diagram source for flow, structure, compliance
- Clean, scriptable Makefile (`make all`, `make gui`, `make firmware`, etc.)
- Output files and folders archived for traceability
- DOT fallback compliance (solid-light option included)

------------------------------------------------------------------------------

DEFAULT FLASH PATTERN LOGIC

Pattern:  
• 3× quick flash (100ms ON / 100ms OFF)  
• 2× medium flash (200ms ON / 200ms OFF)  
• 1× slow flash (400ms ON / 400ms OFF)  
• Full-on hold until brake released

Timing values are customizable via:
- `config/flash_settings.json`
- `gui/config_template.json`
- GUI tool (`gui/emulator_gui.py`)

------------------------------------------------------------------------------

INSTALLATION METHODS

Option A: Silent Script  
Windows:  
    run_all.bat  
macOS / Linux:  
    bash run_all.sh  

Option B: Manual (Advanced)  
1. Launch GUI  
       python gui/emulator_gui.py  
2. Render firmware  
       python scripts/render_config_to_ino.py  
3. Compile  
       arduino-cli compile --fqbn arduino:avr:nano firmware/BrakeFlasher.ino  
4. Upload  
       arduino-cli upload -p /dev/ttyUSB0 --fqbn arduino:avr:nano firmware/BrakeFlasher.ino  

All logs: `logs/flashlog.txt`  
All configs: `config/`  
All outputs: `firmware/`, `output/`, and `sha256_manifest.txt`

------------------------------------------------------------------------------

DIRECTORY MAP (ESSENTIAL)

- gui/                       → Emulator GUI and config templates  
- config/                    → Flash timing patterns, schemas, validation files  
- firmware/                  → Rendered .ino, metadata, compiled outputs  
- scripts/                   → Generator tools, tests, automation  
- docs/                      → GLOSSARY, INSTALLATION_MANUAL, README  
- logs/                      → Persistent timestamped flashlog  
- output/                    → Finalized delivery ZIP with all assets  
- tests/                     → Pytest-based unit validation  
- run_all.sh / .bat          → Single-step automated build/install  
- Makefile                   → Platform-aware build automation

------------------------------------------------------------------------------

VERSIONING AND ROLLBACK

All firmware builds are embedded with:
- SHA256 checksum
- Build timestamp
- Version ID
- Input config snapshot
- Device platform

Rollback:
- Revert to previous `.ino` or `.hex` in `firmware/` or `output/`
- Restore original flash pattern JSON and rerun `render_config_to_ino.py`
- Reference `firmware_version.json` and `sha256_manifest.txt` for audit

------------------------------------------------------------------------------

TESTING

Run:
    make test

Tests verify:
- Flash pattern generation correctness
- INO output matching schema
- GUI response consistency
- Checksum integrity for generated firmware

Coverage:  
- Results output to `coverage_html/index.html`

------------------------------------------------------------------------------

MERMAID DIAGRAMS

Located in: `docs/`  
Use https://mermaid.live or local renderer.

- flow.mmd       → Build, config, and firmware generation sequence  
- structure.mmd  → Project directory and file interaction map  
- compliance.mmd → Metadata schema, jurisdictional anchors, legal trace

------------------------------------------------------------------------------

LEGAL COMPLIANCE

- FMVSS 108: U.S. standard for lighting; flashing third brake lights must comply with local law
- NCGS Ch. 66, 8, 1A: Governs digital evidence admissibility, warranties, and electronic modification
- All outputs hashed (SHA256) and versioned
- Optional fallback mode disables flashing and restores solid-only behavior
- PDF/A-3 outputs, metadata signatures, and X.509 signing supported in enterprise editions

------------------------------------------------------------------------------

SUPPORT AND DELIVERY

Direct Support:  
Jeffrey Plewak (Engineer)  
carcodez1@gmail.com  
Response SLA: 24h (U.S. Eastern Time)

Delivery:  
- All builds include ZIP, checksum, logs, firmware, GUI, and source  
- Ready for GitHub, USB flash drive, or signed ZIP delivery  
- All materials cleared under NDA and IP assignment terms

------------------------------------------------------------------------------

CONCLUSION

This system is fully engineered for safe deployment, legal defensibility, and field installation. Every firmware file, config, and log is verifiable, repeatable, and production-ready. Whether for resale, vehicle safety enhancement, or audit-grade delivery, this toolkit is built for rigorous environments and long-term support.

END OF README
