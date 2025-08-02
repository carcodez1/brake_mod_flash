"""Module: codegen - firmware renderer"""

import json
from pathlib import Path

def render_vehicle(vehicle, config_dir, template_path, output_dir, meta_dir, schema_path):
    config_file = Path(config_dir) / f"{vehicle}.json"
    output_file = Path(output_dir) / f"{vehicle}.ino"
    meta_file = Path(meta_dir) / f"{vehicle}.json"

    print(f"[•] Rendering {vehicle}")
    print(f"    Config:   {config_file}")
    print(f"    Template: {template_path}")
    print(f"    Output:   {output_file}")
    print(f"    Meta:     {meta_file}")

    output_file.parent.mkdir(parents=True, exist_ok=True)
    meta_file.parent.mkdir(parents=True, exist_ok=True)

    # Stub logic: just fake the output
    output_file.write_text(f"// Auto-generated firmware for {vehicle}\nvoid setup() {{}}\nvoid loop() {{}}\n")
    meta_file.write_text(json.dumps({ "vehicle": vehicle, "generated": True }, indent=2))
