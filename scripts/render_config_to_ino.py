#!/usr/bin/env python3
# File: scripts/render_config_to_ino.py
# Version: 2.3.0
# Purpose: Render Arduino .ino firmware from validated JSON flash config using Jinja2
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assignment

import os, sys, json, argparse, hashlib
from datetime import datetime
from jinja2 import Environment, FileSystemLoader
from jsonschema import validate, ValidationError

VERSION = "2.3.0"
DEFAULT_INPUT = "config/vehicles/hyundai_sonata_2020.json"
DEFAULT_TEMPLATE = "firmware/templates/BrakeFlasher.ino.j2"
DEFAULT_OUTPUT = "firmware/sources/BrakeFlasher.ino"
DEFAULT_META = "firmware/metadata/firmware_version.json"
DEFAULT_SCHEMA = "config/schema/flash_pattern.schema.json"

def sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()

def load_json(path: str) -> dict:
    with open(path, "r") as f:
        return json.load(f)

def validate_config(config: dict, schema_path: str):
    schema = load_json(schema_path)
    validate(instance=config, schema=schema)
    for idx, step in enumerate(config["pattern"]):
        if step["count"] <= 0 or step["on"] < 0 or step["off"] < 0:
            raise ValueError(f"Invalid step #{idx}: count>0, on/off ≥ 0 required")

from typing import List, Tuple
def flatten_pattern(pattern: List[dict]) -> Tuple[List[int], List[int]]:
    on = [step["on"] for step in pattern for _ in range(step["count"])]
    off = [step["off"] for step in pattern for _ in range(step["count"])]
    return on, off

def render_firmware(config: dict, template_path: str, output_path: str) -> str:
    env = Environment(loader=FileSystemLoader(os.path.dirname(template_path)))
    template = env.get_template(os.path.basename(template_path))

    timestamp = datetime.utcnow().isoformat() + "Z"
    pattern = config["pattern"]
    on_seq, off_seq = flatten_pattern(pattern)

    render_data = {
        "version": VERSION,
        "timestamp": timestamp,
        "vehicle": config.get("which", {}).get("target_vehicle", ["Unknown"])[0],
        "year": config.get("when", "Unknown").split("-")[0],
        "on": on_seq,
        "off": off_seq,
        "metadata": {
            "pattern_mode": config.get("pattern_mode", "custom"),
            "compliance_level": config.get("compliance_level", "unknown"),
            "who": config.get("who", "unassigned"),
            "why": config.get("why", "unspecified"),
            "where": config.get("where", "undisclosed"),
            "pattern_length": len(pattern)
        }
    }

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        f.write(template.render(render_data))

    print(f"[✓] Firmware rendered: {output_path}")
    return timestamp

def write_metadata(meta_path: str, config: dict, ino_path: str, timestamp: str, config_path: str):
    checksum = sha256_file(ino_path)
    version_short = timestamp.split("T")[0].replace("-", "")
    metadata = {
        "version": VERSION,
        "firmware_version_short": f"v{version_short}",
        "timestamp": timestamp,
        "checksum": checksum,
        "vehicle": config.get("which", {}).get("target_vehicle", ["Unknown"]),
        "pattern_mode": config.get("pattern_mode", "custom"),
        "compliance_level": config.get("compliance_level", "unknown"),
        "pattern_length": len(config["pattern"]),
        "source": os.path.abspath(ino_path),
        "input_config_path": os.path.abspath(config_path),
        "7DP": {
            "who": config.get("who", "unknown"),
            "what": "brake_flasher_firmware",
            "when": timestamp,
            "where": config.get("where", "unknown"),
            "why": config.get("why", "unspecified"),
            "which": config.get("which", {}),
            "how": f"render_config_to_ino.py@{VERSION}"
        }
    }

    os.makedirs(os.path.dirname(meta_path), exist_ok=True)
    with open(meta_path, "w") as f:
        json.dump(metadata, f, indent=2)

    print(f"[✓] Metadata saved: {meta_path}")

def main():
    parser = argparse.ArgumentParser(description="Render Arduino firmware from validated brake flasher config.")
    parser.add_argument("--input", default=DEFAULT_INPUT, help="Input JSON config path")
    parser.add_argument("--template", default=DEFAULT_TEMPLATE, help="Jinja2 template path")
    parser.add_argument("--output", default=DEFAULT_OUTPUT, help="Output .ino file path")
    parser.add_argument("--meta", default=DEFAULT_META, help="Output metadata JSON path")
    parser.add_argument("--schema", default=DEFAULT_SCHEMA, help="JSON Schema path for config validation")
    args = parser.parse_args()

    try:
        config = load_json(args.input)
        validate_config(config, args.schema)
        timestamp = render_firmware(config, args.template, args.output)
        write_metadata(args.meta, config, args.output, timestamp, args.input)
    except (ValidationError, ValueError) as e:
        print(f"[✗] Config error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"[✗] Fatal error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
