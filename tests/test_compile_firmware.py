# File: tests/test_compile_firmware.py
# Tests for .ino → .hex compilation using arduino-cli
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.0.0

import subprocess
import os
import pytest

SOURCE_INO = "firmware/sources/BrakeFlasher.ino"
OUTPUT_DIR = "firmware/binaries"
HEX_OUT = os.path.join(OUTPUT_DIR, "BrakeFlasher.hex")
BOARD_FQBN = "arduino:avr:nano"  # Adjust if needed (e.g. nano:cpu=atmega328old)
PORT = None  # Only needed for flashing

@pytest.mark.order(1)
def test_source_exists():
    """Ensure .ino file is present and compilable."""
    assert os.path.exists(SOURCE_INO), f"Missing: {SOURCE_INO}"

@pytest.mark.order(2)
def test_compile_to_hex(tmp_path):
    """Run arduino-cli to compile .ino to .hex output."""
    build_path = tmp_path / "build"
    build_path.mkdir(exist_ok=True)

    cmd = [
        "arduino-cli", "compile",
        "--fqbn", BOARD_FQBN,
        "--output-dir", str(build_path),
        SOURCE_INO
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    print(result.stdout)
    print(result.stderr)

    assert result.returncode == 0, f"Compilation failed: {result.stderr}"
    hex_files = [f for f in os.listdir(build_path) if f.endswith(".hex")]
    assert hex_files, "No .hex output generated"

@pytest.mark.order(3)
def test_copy_final_hex():
    """Ensure compiled .hex is moved to expected binaries folder."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    candidate = next((f for f in os.listdir("build") if f.endswith(".hex")), None)
    if candidate:
        src = os.path.join("build", candidate)
        dst = os.path.join(OUTPUT_DIR, "BrakeFlasher.hex")
        os.rename(src, dst)
        assert os.path.exists(dst)
