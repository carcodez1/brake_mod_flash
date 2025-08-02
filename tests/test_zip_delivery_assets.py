# File: tests/test_zip_delivery_assets.py
# Verifies delivery ZIP creation per vehicle configuration
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.0.0

import os
import zipfile
import json
import pytest

DELIVERY_DIR = "output/zips"
VEHICLE_ID = "hyundai_sonata_2020"
EXPECTED_CONTENTS = [
    f"firmware/sources/{VEHICLE_ID}.ino",
    f"firmware/binaries/{VEHICLE_ID}.hex",
    f"firmware/metadata/{VEHICLE_ID}.json",
    "logs/",
    "sha256_manifest.txt"
]

def find_latest_zip(vehicle_id):
    files = [f for f in os.listdir(DELIVERY_DIR) if f.endswith(".zip") and vehicle_id in f]
    assert files, f"No ZIPs found for vehicle: {vehicle_id}"
    files.sort(reverse=True)
    return os.path.join(DELIVERY_DIR, files[0])

def test_zip_exists():
    """Confirm the delivery ZIP file was generated."""
    zip_path = find_latest_zip(VEHICLE_ID)
    assert os.path.exists(zip_path), f"Missing ZIP: {zip_path}"

def test_zip_contents_match_expected():
    """Verify all required components are in the delivery ZIP."""
    zip_path = find_latest_zip(VEHICLE_ID)
    with zipfile.ZipFile(zip_path, "r") as zipf:
        members = zipf.namelist()
        for expected in EXPECTED_CONTENTS:
            match = any(expected in member for member in members)
            assert match, f"Missing expected item in ZIP: {expected}"

def test_zip_metadata_valid():
    """Parse metadata inside ZIP and ensure valid JSON structure."""
    zip_path = find_latest_zip(VEHICLE_ID)
    with zipfile.ZipFile(zip_path, "r") as zipf:
        meta_files = [m for m in zipf.namelist() if m.endswith(".json") and "metadata" in m]
        assert meta_files, "No metadata JSON found in ZIP"
        with zipf.open(meta_files[0]) as mf:
            meta = json.load(mf)
            assert "version" in meta
            assert "generated" in meta
            assert "checksum" in meta
