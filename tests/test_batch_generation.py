# File: tests/test_batch_generation.py
# Purpose: Verify all vehicle firmware + assets are generated as expected
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assignment
# Version: 1.0.0

import os
import glob
import json
import pytest

CONFIG_DIR = "config/vehicles"
SOURCE_DIR = "firmware/sources"
BIN_DIR = "firmware/binaries"
ZIP_DIR = "output/zips"

@pytest.mark.parametrize("config_path", glob.glob(f"{CONFIG_DIR}/*.json"))
def test_vehicle_assets_generated(config_path):
    vehicle = os.path.splitext(os.path.basename(config_path))[0]
    ino_path = f"{SOURCE_DIR}/{vehicle}.ino"
    hex_path = f"{BIN_DIR}/{vehicle}.hex"
    zip_glob = glob.glob(f"{ZIP_DIR}/{vehicle}_*.zip")

    assert os.path.exists(config_path), f"Config missing: {config_path}"
    assert os.path.isfile(ino_path), f".ino file missing: {ino_path}"
    assert os.path.isfile(hex_path), f".hex file missing: {hex_path}"
    assert len(zip_glob) > 0, f"No ZIP output found for: {vehicle}"

@pytest.mark.parametrize("ino_file", glob.glob(f"{SOURCE_DIR}/*.ino"))
def test_ino_syntax(ino_file):
    with open(ino_file, "r") as f:
        content = f.read()
    assert "void setup()" in content and "void loop()" in content, f"Malformed INO: {ino_file}"

def test_all_configs_parsable():
    for path in glob.glob(f"{CONFIG_DIR}/*.json"):
        with open(path, "r") as f:
            try:
                json.load(f)
            except Exception as e:
                pytest.fail(f"Invalid JSON in {path}: {e}")
