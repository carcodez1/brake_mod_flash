BrakeFlasher Toolkit v1.0.1  
Principal Engineer: Jeffrey Plewak  
Contact: carcodez1@gmail.com  
Build Timestamp: 2025-07-26T00:00:00Z  
License: Proprietary (NDA + IP Assignment Enforced)  
Target Vehicles: Hyundai, Kia  
Target Component: Third Brake Light  
Target Hardware: Arduino Nano (ATmega328P, 5V, 16MHz)  

--------------------------------------------------------------------------------
SUMMARY
--------------------------------------------------------------------------------
This toolkit implements a legal-grade, revertible brake flasher modification for  
Hyundai and Kia vehicles. It enables a customizable flashing pattern on the third  
brake light, with legally admissible metadata, compiled firmware, an emulator GUI,  
auto-config conversion, and a fully silent installation pipeline.  

--------------------------------------------------------------------------------
7DP STRUCTURED PROVENANCE
--------------------------------------------------------------------------------
Who    : Jeffrey Plewak (Principal Engineer), client identity under NDA  
What   : Brake light firmware, GUI emulator, metadata, and automation tools  
When   : 2025-07-26T00:00:00Z (firmware_version.json + git tags)  
Where  : United States — distributed under NDA / IP assignment  
Why    : Aftermarket safety upgrade for rear-end collision mitigation  
Which  : Third brake light input D3 (active HIGH), output D4 (5V)  
How    : Arduino firmware, Python GUI, metadata schema, compliance exports  

Metadata Files:  
- firmware/metadata/firmware_version.json  
- config/flash_settings.json  
- docs/README.md  
- logs/flashlog.txt  
- scripts/render_config_to_ino.py  
- config/input_schema.json (validation)  

--------------------------------------------------------------------------------
KEY FEATURES
--------------------------------------------------------------------------------
- Custom flashing firmware (Arduino Nano)  
- JSON-configurable flash logic  
- GUI Emulator (`gui/emulator_gui.py`) with live signal preview  
- Config file conversion to `.ino` via `scripts/render_config_to_ino.py`  
- Version tracking and rollback (firmware_version.json)  
- Daily logs (logs/flashlog.txt, microsecond timestamps)  
- SHA256 integrity via structured config/log schema  
- Mermaid diagrams for flow, compliance, and structure  
- Silent installation with `run_all.sh` / `run_all.bat`  
- GitHub Actions-ready: versioning, packaging, checksum validation  

--------------------------------------------------------------------------------
FLASHING LOGIC (DEFAULT)
--------------------------------------------------------------------------------
Input Pin: D3  
Output Pin: D4  
Sequence:  
  - 3× 100ms ON / 100ms OFF  
  - 2× 200ms ON / 200ms OFF  
  - 1× 400ms ON / 400ms OFF  
  - Hold ON  

Modify pattern via:  
  - `config/flash_settings.json`  
  - `gui/config_template.json`  
  - GUI emulator or directly edit + render via `render_config_to_ino.py`  

--------------------------------------------------------------------------------
DIRECTORY STRUCTURE
--------------------------------------------------------------------------------
├── BrakeFLashEmulator.spec           # PyInstaller spec for EXE  
├── LICENSE                           # IP & NDA notice  
├── build/                            # Compiled .hex artifacts  
│   └── brake_flasher_default.hex  
├── config/                           # Flash pattern config + schema  
│   ├── flash_settings.json  
│   ├── input_schema.json  
│   └── settings.yaml  
├── docs/                             # Legal README, diagrams  
│   └── README.md  
├── firmware/                         # Arduino firmware  
│   ├── BrakeFlasher.ino  
│   ├── metadata/firmware_version.json  
│   └── template.ino  
├── gui/                              # GUI frontend  
│   ├── config_template.json  
│   └── emulator_gui.py  
├── logs/                             # Rotated logs  
│   └── flashlog.txt  
├── run_all.bat                       # Windows install + build  
├── run_all.sh                        # macOS/Linux install + build  
├── scripts/                          # Core scripts  
│   ├── render_config_to_ino.py       # Converts config -> firmware  
│   ├── run_tests.py  
│   └── telemetry.py                  # Placeholder for future data  
├── tests/                            # Unit tests  
│   └── test_render_config_to_ino.py  

--------------------------------------------------------------------------------
INSTALLATION
--------------------------------------------------------------------------------
Windows (silent, auto-detect):  
    run_all.bat  

macOS / Linux (silent):  
    bash run_all.sh  

These scripts validate dependencies, render firmware, compile, and optionally flash.  
All actions logged to `logs/flashlog.txt`.  

--------------------------------------------------------------------------------
USAGE
--------------------------------------------------------------------------------
Preview Flash Pattern (GUI):  
    python gui/emulator_gui.py  

Render `.ino` from config:  
    python scripts/render_config_to_ino.py  

Compile firmware:  
    arduino-cli compile --fqbn arduino:avr:nano firmware/BrakeFlasher.ino  

Upload to Arduino:  
    arduino-cli upload -p /dev/ttyUSB0 --fqbn arduino:avr:nano firmware/BrakeFlasher.ino  

--------------------------------------------------------------------------------
ROLLBACK / VERSIONING
--------------------------------------------------------------------------------
- `firmware_version.json` contains: version, hash, timestamp, platform  
- Previous versions archived in build/  
- Git commit/tag metadata used for traceability  
- Rollback: use prior `.hex` or restore config then rerun script  

--------------------------------------------------------------------------------
MERMAID DIAGRAMS (docs/)
--------------------------------------------------------------------------------
View `.mmd` via: https://mermaid.live  
- flow.mmd: Build/flash sequence  
- structure.mmd: File structure  
- compliance.mmd: Metadata + legal trace  

--------------------------------------------------------------------------------
LEGAL / COMPLIANCE
--------------------------------------------------------------------------------
- All files are SHA256-hashed and traceable  
- Compliant with ISO 19005 (PDF/A), JSON-LD 1.1  
- Jurisdiction: North Carolina General Statutes (NCGS Ch. 66, 8, 1A)  
- PDF exports optionally signed with X.509/PAdES-BES  
- Redistribution and modification prohibited under NDA  

--------------------------------------------------------------------------------
SUPPORT
--------------------------------------------------------------------------------
Engineer: Jeffrey Plewak  
Email: carcodez1@gmail.com  
Tier 1 Direct Support (24h SLA, EST)  

--------------------------------------------------------------------------------
END OF DOCUMENT
