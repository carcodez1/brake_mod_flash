import core.logger as logger
# File: core/firmware.py
# Purpose: Invokes firmware generator from validated config
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assigned
# Version: 1.5.0

import subprocess
import json
import os
import sys
from core import state, logger

SCRIPT_PATH = "scripts/render_config_to_ino.py"
SCHEMA_PATH = "config/schema/flash_pattern.schema.json"
OUT_INO = "firmware/sources/BrakeFlasher.ino"
OUT_META = "firmware/metadata/firmware_version.json"

def build_firmware():
    config_path = state.config_path_var.get()

    if not config_path or not os.path.isfile(config_path):
        logger.log("[!] Save or load a valid config first.")
        return False

    cmd = [
        sys.executable, SCRIPT_PATH,
        "--input", config_path,
        "--output", OUT_INO,
        "--meta", OUT_META,
        "--schema", SCHEMA_PATH
    ]

    logger.log(f"[↻] Building firmware: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        logger.log(result.stderr.strip())
        return False

    try:
        with open(OUT_META) as f:
            meta = json.load(f)
        state.version_var.set(f"{meta.get('version')} @ {meta.get('generated')}")
        state.output_path_var.set(OUT_INO)
        logger.log(f"[✓] Firmware built: v{meta.get('version')}")
        return True
    except Exception as e:
        logger.log(f"[!] Metadata parse failed: {e}")
        return False
