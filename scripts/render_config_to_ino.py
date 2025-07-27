#!/usr/bin/env python3
# File: scripts/render_config_to_ino.py
# Purpose: Convert validated JSON config into Arduino .ino firmware
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.2.0

import os
import json
import argparse
from datetime import datetime
from jinja2 import Environment, FileSystemLoader, select_autoescape

# ─────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE_DIR = os.path.join(ROOT, "firmware", "templates")
DEFAULT_TEMPLATE = "BrakeFlasher.ino.j2"
DEFAULT_CONFIG = os.path.join(ROOT, "gui", "config_template.json")
DEFAULT_OUTPUT_INO = os.path.join(ROOT, "firmware", "BrakeFlasher.ino")
DEFAULT_OUTPUT_META = os.path.join(ROOT, "firmware", "metadata", "firmware_version.json")

env = Environment(
    loader=FileSystemLoader(TEMPLATE_DIR),
    autoescape=select_autoescape(['j2'])
)

# ─────────────────────────────────────────────────────────────
# PARSE ARGUMENTS
# ─────────────────────────────────────────────────────────────
parser = argparse.ArgumentParser(description="Render Arduino .ino firmware from a JSON config")
parser.add_argument('--config', type=str, default=DEFAULT_CONFIG, help="Path to config JSON")
parser.add_argument('--output', type=str, default=DEFAULT_OUTPUT_INO, help="Path to output .ino")
parser.add_argument('--meta', type=str, default=DEFAULT_OUTPUT_META, help="Path to metadata JSON")
parser.add_argument('--template', type=str, default=DEFAULT_TEMPLATE, help="Jinja2 template filename")
args = parser.parse_args()

# ─────────────────────────────────────────────────────────────
# LOAD AND VALIDATE CONFIG
# ─────────────────────────────────────────────────────────────
if not os.path.isfile(args.config):
    raise FileNotFoundError(f"Config file not found: {args.config}")

with open(args.config, 'r') as f:
    config = json.load(f)

if not isinstance(config.get("pattern"), list) or len(config["pattern"]) == 0:
    raise ValueError("Config missing valid 'pattern' key with flash sequence")

# ─────────────────────────────────────────────────────────────
# RENDER FIRMWARE (.ino) FROM TEMPLATE
# ─────────────────────────────────────────────────────────────
template = env.get_template(args.template)
timestamp = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
version = config.get("version", "1.0.0")

rendered_code = template.render(
    pattern=config["pattern"],
    pin_in=config.get("pin_in", 3),
    pin_out=config.get("pin_out", 4),
    version=version,
    timestamp=timestamp,
    description=config.get("description", "Generated firmware"),
)

os.makedirs(os.path.dirname(args.output), exist_ok=True)
with open(args.output, 'w') as f:
    f.write(rendered_code)

# ─────────────────────────────────────────────────────────────
# GENERATE METADATA (.json)
# ─────────────────────────────────────────────────────────────
metadata = {
    "vehicle": config.get("vehicle", "unspecified"),
    "version": version,
    "timestamp": timestamp,
    "pattern_length": len(config["pattern"]),
    "input_pin": config.get("pin_in", 3),
    "output_pin": config.get("pin_out", 4),
    "description": config.get("description", ""),
    "source_config": os.path.basename(args.config),
    "generated_by": "render_config_to_ino.py"
}

os.makedirs(os.path.dirname(args.meta), exist_ok=True)
with open(args.meta, 'w') as f:
    json.dump(metadata, f, indent=2)

# ─────────────────────────────────────────────────────────────
# SUCCESS
# ─────────────────────────────────────────────────────────────
print(f"[✓] Firmware written to {args.output}")
print(f"[✓] Metadata written to {args.meta}")
