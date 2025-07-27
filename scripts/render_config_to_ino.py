#!/usr/bin/env python3
# File: scripts/render_config_to_ino.py
# Purpose: Render Arduino .ino firmware from validated JSON pattern using Jinja2
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assignment

import os
import sys
import json
import argparse
from datetime import datetime
from jinja2 import Environment, FileSystemLoader

VERSION = "1.0.0"

def load_config(path: str) -> dict:
    try:
        with open(path, "r") as f:
            data = json.load(f)
        if isinstance(data, list):
            raise ValueError("Expected object with key 'pattern', but got a list.")
        if "pattern" not in data or not isinstance(data["pattern"], list):
            raise ValueError("Missing or invalid 'pattern' key in config.")
        return data
    except Exception as e:
        print(f"[✗] Failed to load config: {e}", file=sys.stderr)
        sys.exit(1)

def render_firmware(config: dict, template_path: str, output_path: str):
    try:
        env = Environment(loader=FileSystemLoader(os.path.dirname(template_path)))
        template = env.get_template(os.path.basename(template_path))
        now = datetime.utcnow().isoformat()
        pattern = config["pattern"]

        rendered = template.render(
            version=VERSION,
            timestamp=now,
            vehicle=config.get("which", {}).get("target_vehicle", ["Unknown"])[0],
            year=config.get("when", "Unknown").split("-")[0],
            on=[step["on"] for step in pattern for _ in range(step["count"])],
            off=[step["off"] for step in pattern for _ in range(step["count"])]
        )

        with open(output_path, "w") as f:
            f.write(rendered)
        print(f"[✓] Firmware rendered: {output_path}")
    except Exception as e:
        print(f"[✗] Rendering failed: {e}", file=sys.stderr)
        sys.exit(1)

def write_metadata(meta_path: str, config: dict):
    try:
        metadata = {
            "version": VERSION,
            "timestamp": datetime.utcnow().isoformat(),
            "vehicle": config.get("which", {}).get("target_vehicle", ["Unknown"]),
            "source": "render_config_to_ino.py",
            "pattern_hash": hash(json.dumps(config["pattern"]))
        }
        os.makedirs(os.path.dirname(meta_path), exist_ok=True)
        with open(meta_path, "w") as f:
            json.dump(metadata, f, indent=2)
        print(f"[✓] Metadata saved: {meta_path}")
    except Exception as e:
        print(f"[✗] Metadata write failed: {e}", file=sys.stderr)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Render Arduino firmware from JSON config.")
    parser.add_argument("--input", default="gui/config_template.json", help="Input config path")
    parser.add_argument("--template", default="firmware/templates/BrakeFlasher.ino.j2", help="Jinja template path")
    parser.add_argument("--output", default="firmware/BrakeFlasher.ino", help="Output .ino file path")
    parser.add_argument("--meta", default="firmware/metadata/firmware_version.json", help="Output metadata path")

    args = parser.parse_args()
    config = load_config(args.input)
    render_firmware(config, args.template, args.output)
    write_metadata(args.meta, config)
