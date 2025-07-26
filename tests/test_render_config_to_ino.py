# File: tests/test_render_config_to_ino.py
# Author: Jeffrey Plewak
# Purpose: Unit tests for render_config_to_ino.py with ~80–90% coverage
# License: Proprietary – NDA / IP Assigned

import pytest
import json
import os
import tempfile
from unittest import mock
from scripts.render_config_to_ino import (
    generate_pattern_block,
    write_ino_file,
    write_metadata,
    compute_and_save_hash
)

def test_generate_pattern_block_typical():
    config = {"pattern": [{"on": 150, "off": 300}, {"on": 200, "off": 400}]}
    block = generate_pattern_block(config)
    assert "delay(150);" in block
    assert "delay(400);" in block
    assert block.count("digitalWrite(outputPin, HIGH)") == 2

def test_generate_pattern_block_empty():
    config = {"pattern": []}
    block = generate_pattern_block(config)
    assert block.strip() == ""

def test_generate_pattern_block_missing_key():
    config = {}
    block = generate_pattern_block(config)
    assert block.strip() == ""

def test_write_ino_file_creates_valid_output(tmp_path):
    file_path = tmp_path / "BrakeFlasher.ino"
    os.environ["OUTPUT_INO_PATH"] = str(file_path)  # optional if script reads env
    code = write_ino_file("    digitalWrite(outputPin, HIGH); delay(123);", "2.2.2")
    assert "Version: 2.2.2" in code
    assert "delay(123);" in code
    assert "pinMode" in code
    assert "outputPin" in code

def test_write_metadata_creates_json(tmp_path):
    path = tmp_path / "firmware_version.json"
    os.environ["OUTPUT_META_PATH"] = str(path)  # optional if script reads env
    meta = write_metadata("9.9.9", "2025-07-26T00:00:00Z")
    assert meta["version"] == "9.9.9"
    assert meta["timestamp"].startswith("2025-07-26")
    assert "tool" in meta
    assert "input_pin" in meta

def test_compute_and_save_hash_content(tmp_path):
    f = tmp_path / "firmware.ino"
    f.write_text("// test")
    hash_path = tmp_path / "firmware_hash.sha256"
    hash_str = compute_and_save_hash(str(f), str(hash_path))
    assert len(hash_str) == 64
    assert hash_path.exists()
    with open(hash_path) as h:
        assert hash_str in h.read()

def test_compute_and_save_hash_mocked(tmp_path):
    f = tmp_path / "dummy.txt"
    f.write_text("hello world")
    hash_path = tmp_path / "out.sha256"
    with mock.patch("hashlib.sha256") as mock_hash:
        mock_hash.return_value.hexdigest.return_value = "a" * 64
        out = compute_and_save_hash(str(f), str(hash_path))
        assert out == "a" * 64

def test_write_ino_file_output_has_pin_definitions():
    code = write_ino_file("    // no pattern", "3.3.3")
    assert "inputPin = 3" in code
    assert "outputPin = 4" in code
