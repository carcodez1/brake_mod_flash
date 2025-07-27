#!/usr/bin/env python3
# File: scripts/delivery.py
# Purpose: Package finalized firmware output folders into delivery ZIPs
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 2.0.0

import os
import zipfile
import hashlib
from datetime import datetime
from pathlib import Path

# ─────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────
ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIR = ROOT / "output"
ZIP_DIR = OUTPUT_DIR / "zips"
MANIFEST_FILE = ROOT / "sha256_manifest.txt"
INCLUDE_EXT = {".ino", ".hex", ".json"}

timestamp = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
ZIP_DIR.mkdir(parents=True, exist_ok=True)
hash_entries = []

print("────────────────────────────────────────────────────────────")
print("DELIVERY PACKAGING")
print(f"Output Root : {OUTPUT_DIR}")
print(f"ZIP Output  : {ZIP_DIR}")
print(f"Timestamp   : {timestamp}")
print("────────────────────────────────────────────────────────────")

# ─────────────────────────────────────────────────────────────
# ZIP EACH VEHICLE FOLDER
# ─────────────────────────────────────────────────────────────
vehicles_zipped = 0
for vehicle_dir in OUTPUT_DIR.iterdir():
    if not vehicle_dir.is_dir() or vehicle_dir.name == "zips":
        continue

    archive_name = f"{vehicle_dir.name}_{timestamp}.zip"
    zip_path = ZIP_DIR / archive_name

    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for file_path in vehicle_dir.rglob("*"):
            if file_path.suffix in INCLUDE_EXT:
                arcname = file_path.relative_to(vehicle_dir)
                zipf.write(file_path, arcname)

    sha256 = hashlib.sha256(zip_path.read_bytes()).hexdigest()
    hash_entries.append(f"{sha256}  {zip_path.name}")
    vehicles_zipped += 1
    print(f"[✓] Zipped: {zip_path.name}")

# ─────────────────────────────────────────────────────────────
# WRITE MANIFEST
# ─────────────────────────────────────────────────────────────
MANIFEST_FILE.write_text("\n".join(hash_entries) + "\n")
print("────────────────────────────────────────────────────────────")
print(f"ZIP Packages  : {vehicles_zipped}")
print(f"Manifest File : {MANIFEST_FILE}")
print("────────────────────────────────────────────────────────────")

if vehicles_zipped == 0:
    print("WARNING: No packages were created. Check output/ structure.")
