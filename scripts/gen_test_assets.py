#!/usr/bin/env python3
# File: scripts/gen_test_assets.py
# Purpose: Generate schema-valid vehicle pattern JSONs for testing
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.0.0

import json, os
from datetime import datetime
from pathlib import Path

CONFIG_DIR = Path("config/vehicles")
CONFIG_DIR.mkdir(parents=True, exist_ok=True)

VEHICLE_PRESETS = {
    "hyundai_sonata_2018": {
        "pattern_mode": "default",
        "compliance_level": "standard",
        "version": "1.0.0",
        "pattern": [{"count": 3, "on": 100, "off": 150}]
    },
    "kia_optima_2020": {
        "pattern_mode": "luxury",
        "compliance_level": "europe",
        "version": "1.0.0",
        "pattern": [{"count": 2, "on": 120, "off": 180}, {"count": 1, "on": 600, "off": 0}]
    },
    "genesis_g70_2022": {
        "pattern_mode": "aggressive",
        "compliance_level": "track",
        "version": "1.0.0",
        "pattern": [{"count": 5, "on": 90, "off": 110}]
    }
}

def write_config(vehicle_id, data):
    path = CONFIG_DIR / f"{vehicle_id}.json"
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
    print(f"[✓] Generated: {path}")

if __name__ == "__main__":
    for vehicle_id, data in VEHICLE_PRESETS.items():
        data["generated"] = datetime.utcnow().isoformat() + "Z"
        write_config(vehicle_id, data)

