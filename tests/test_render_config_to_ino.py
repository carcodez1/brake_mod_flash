# File: tests/test_render_config_to_ino.py
# Tests for render_config_to_ino.py (enterprise firmware generator)
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.1.0
# Purpose: Validate rendering of .ino and metadata output from vehicle config

import json
import subprocess
import os
import sys
import pytest

# Paths to valid, invalid, and corrupted config files
CONFIG_VALID = "config/vehicles/hyundai_sonata_2020.json"
CONFIG_INVALID = "tests/assets/invalid_pattern.json"
CONFIG_CORRUPT = "tests/assets/corrupt_pattern.json"

# Template and schema paths (must exist for the test to pass)
TEMPLATE = "firmware/templates/BrakeFlasher.ino.j2"
SCHEMA = "config/schema/flash_pattern.schema.json"

def test_render_success(tmp_path):
    """Test that valid input produces correct .ino and metadata output."""
    out_ino = tmp_path / "BrakeFlasher.ino"
    out_meta = tmp_path / "firmware_version.json"

    result = subprocess.run([
        sys.executable, "scripts/render_config_to_ino.py",
        "--input", CONFIG_VALID,
        "--template", TEMPLATE,
        "--output", str(out_ino),
        "--meta", str(out_meta),
        "--schema", SCHEMA
    ], capture_output=True, text=True)

    assert result.returncode == 0
    assert out_ino.exists()
    assert out_meta.exists()

    with open(out_meta) as f:
        meta = json.load(f)
        assert "checksum" in meta
        assert meta["pattern_length"] > 0
        assert TEMPLATE not in meta.get("source", "")

    with open(out_ino) as f:
        ino_content = f.read()
        assert "pinMode(outputPin, OUTPUT);" in ino_content
        assert "digitalRead(inputPin) == HIGH" in ino_content
        assert "delay(" in ino_content

def test_render_fail_schema(tmp_path):
    """Test that schema-invalid input returns non-zero exit code and stderr."""
    out_ino = tmp_path / "BrakeFlasher.ino"
    out_meta = tmp_path / "firmware_version.json"

    result = subprocess.run([
        sys.executable, "scripts/render_config_to_ino.py",
        "--input", CONFIG_INVALID,
        "--template", TEMPLATE,
        "--output", str(out_ino),
        "--meta", str(out_meta),
        "--schema", SCHEMA
    ], capture_output=True, text=True)

    assert result.returncode != 0
    assert "Validation error" in result.stderr or "Config error" in result.stderr

def test_render_fail_corrupt_json(tmp_path):
    """Test that corrupt JSON input returns error and clean failure."""
    out_ino = tmp_path / "BrakeFlasher.ino"
    out_meta = tmp_path / "firmware_version.json"

    result = subprocess.run([
        sys.executable, "scripts/render_config_to_ino.py",
        "--input", CONFIG_CORRUPT,
        "--template", TEMPLATE,
        "--output", str(out_ino),
        "--meta", str(out_meta),
        "--schema", SCHEMA
    ], capture_output=True, text=True)

    assert result.returncode != 0
    assert "Invalid JSON" in result.stderr or "Expecting value" in result.stderr
def test_render_fail_empty_pattern(tmp_path):
    """Reject config with empty pattern array."""
    config = tmp_path / "empty_pattern.json"
    config.write_text(json.dumps({
        "pattern": [],
        "pattern_mode": "default",
        "metadata": {"vehicle": "test"}
    }))

    result = subprocess.run([
        sys.executable, "scripts/render_config_to_ino.py",
        "--input", str(config),
        "--template", TEMPLATE,
        "--output", str(tmp_path / "out.ino"),
        "--meta", str(tmp_path / "meta.json"),
        "--schema", SCHEMA
    ], capture_output=True, text=True)

    assert result.returncode != 0
    assert "pattern" in result.stderr or "too short" in result.stderr

def test_render_fail_bad_pattern_mode(tmp_path):
    """Reject unknown pattern_mode string."""
    config = tmp_path / "bad_mode.json"
    config.write_text(json.dumps({
        "pattern": [{"count": 3, "on": 100, "off": 100}],
        "pattern_mode": "ludicrous",  # not in enum
        "metadata": {"vehicle": "test"}
    }))

    result = subprocess.run([
        sys.executable, "scripts/render_config_to_ino.py",
        "--input", str(config),
        "--template", TEMPLATE,
        "--output", str(tmp_path / "out.ino"),
        "--meta", str(tmp_path / "meta.json"),
        "--schema", SCHEMA
    ], capture_output=True, text=True)

    assert result.returncode != 0
    assert "pattern_mode" in result.stderr or "enum" in result.stderr

def test_render_fail_negative_delay(tmp_path):
    """Reject flash steps with negative on/off durations."""
    config = tmp_path / "negative_delay.json"
    config.write_text(json.dumps({
        "pattern": [{"count": 3, "on": -50, "off": -10}],
        "pattern_mode": "default",
        "metadata": {"vehicle": "test"}
    }))

    result = subprocess.run([
        sys.executable, "scripts/render_config_to_ino.py",
        "--input", str(config),
        "--template", TEMPLATE,
        "--output", str(tmp_path / "out.ino"),
        "--meta", str(tmp_path / "meta.json"),
        "--schema", SCHEMA
    ], capture_output=True, text=True)

    assert result.returncode != 0
    assert "on" in result.stderr or "minimum" in result.stderr
def test_render_fail_non_integer_count(tmp_path):
    """Reject flash step with non-integer count."""
    config = tmp_path / "nonint_count.json"
    config.write_text(json.dumps({
        "pattern": [{"count": "five", "on": 100, "off": 100}],
        "pattern_mode": "default",
        "metadata": {"vehicle": "test"}
    }))

    result = subprocess.run([
        sys.executable, "scripts/render_config_to_ino.py",
        "--input", str(config),
        "--template", TEMPLATE,
        "--output", str(tmp_path / "out.ino"),
        "--meta", str(tmp_path / "meta.json"),
        "--schema", SCHEMA
    ], capture_output=True, text=True)

    assert result.returncode != 0
    assert "count" in result.stderr or "type" in result.stderr


def test_render_fail_missing_template(tmp_path):
    """Fail cleanly when template file is missing."""
    config = tmp_path / "valid_config.json"
    config.write_text(json.dumps({
        "pattern": [{"count": 2, "on": 100, "off": 100}],
        "pattern_mode": "default",
        "metadata": {"vehicle": "test"}
    }))

    result = subprocess.run([
        sys.executable, "scripts/render_config_to_ino.py",
        "--input", str(config),
        "--template", "firmware/templates/MISSING_TEMPLATE.j2",
        "--output", str(tmp_path / "out.ino"),
        "--meta", str(tmp_path / "meta.json"),
        "--schema", SCHEMA
    ], capture_output=True, text=True)

    assert result.returncode != 0
    assert "Template file not found" in result.stderr or "No such file" in result.stderr
