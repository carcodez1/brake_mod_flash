# File: scripts/render_config_to_ino.py
# Converts validated flash config JSON into Arduino INO firmware
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assigned
# Version: 1.0.1
# Date: 2025-07-26

import json
import os
from datetime import datetime
import hashlib

INPUT_CONFIG_PATH = "gui/config_template.json"
OUTPUT_INO_PATH = "firmware/BrakeFlasher.ino"
OUTPUT_META_PATH = "firmware/metadata/firmware_version.json"
OUTPUT_HASH_PATH = "firmware/metadata/firmware_hash.sha256"

TEMPLATE_HEADER = """\
// Auto-generated Arduino firmware (.ino)
// DO NOT MODIFY BY HAND – use render_config_to_ino.py
// Author: Jeffrey Plewak
// Date: {timestamp}
// Version: {version}
// Pinout: Input on D3 (active HIGH), Output on D4
"""

TEMPLATE_CODE = """\
const int inputPin = 3;
const int outputPin = 4;

void setup() {{
  pinMode(inputPin, INPUT);
  pinMode(outputPin, OUTPUT);
}}

void loop() {{
  if (digitalRead(inputPin) == HIGH) {{
{pattern_block}
  }} else {{
    digitalWrite(outputPin, LOW);
  }}
}}
"""

PATTERN_LINE_TEMPLATE = "    digitalWrite(outputPin, HIGH); delay({on});// ON\n    digitalWrite(outputPin, LOW); delay({off});// OFF\n"

def generate_pattern_block(config_data):
    pattern_lines = []
    for i, entry in enumerate(config_data.get("pattern", [])):
        on = int(entry.get("on", 0))
        off = int(entry.get("off", 0))
        pattern_lines.append(PATTERN_LINE_TEMPLATE.format(on=on, off=off))
    return ''.join(pattern_lines)

def write_ino_file(pattern_block, version):
    timestamp = datetime.utcnow().isoformat()
    header = TEMPLATE_HEADER.format(timestamp=timestamp, version=version)
    full_code = header + "\n" + TEMPLATE_CODE.format(pattern_block=pattern_block)
    with open(OUTPUT_INO_PATH, "w") as f:
        f.write(full_code)
    return full_code

def write_metadata(version, timestamp):
    metadata = {
        "version": version,
        "timestamp": timestamp,
        "input_pin": "D3",
        "output_pin": "D4",
        "tool": "render_config_to_ino.py",
        "author": "Jeffrey Plewak"
    }
    with open(OUTPUT_META_PATH, "w") as f:
        json.dump(metadata, f, indent=2)
    return metadata

def compute_and_save_hash(file_path, hash_path):
    with open(file_path, "rb") as f:
        file_bytes = f.read()
        sha256 = hashlib.sha256(file_bytes).hexdigest()
    with open(hash_path, "w") as f:
        f.write(f"{sha256}  {os.path.basename(file_path)}\n")
    return sha256

def main():
    version = "1.0.1"
    with open(INPUT_CONFIG_PATH, "r") as f:
        config_data = json.load(f)
    pattern_block = generate_pattern_block(config_data)
    firmware_code = write_ino_file(pattern_block, version)
    timestamp = datetime.utcnow().isoformat()
    write_metadata(version, timestamp)
    compute_and_save_hash(OUTPUT_INO_PATH, OUTPUT_HASH_PATH)

if __name__ == "__main__":
    main()
