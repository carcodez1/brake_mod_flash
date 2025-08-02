# File: tests/test_flash_logs.py
# Purpose: Ensure flash logs exist for each .hex and contain success indicator
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assignment

import os
import glob
import pytest

BIN_DIR = "firmware/binaries"
LOG_DIR = "logs"

@pytest.mark.parametrize("hex_file", glob.glob(f"{BIN_DIR}/*.hex"))
def test_flash_log_exists_and_success(hex_file):
    vehicle = os.path.splitext(os.path.basename(hex_file))[0]
    candidates = glob.glob(f"{LOG_DIR}/flash_{vehicle}_*.log")
    assert candidates, f"No flash log found for: {vehicle}"

    found_success = False
    for log_file in candidates:
        with open(log_file, "r", errors="ignore") as f:
            content = f.read()
            if "bytes of flash verified" in content or "flash verified" in content:
                found_success = True
                break

    assert found_success, f"No success marker found in logs for {vehicle}"
