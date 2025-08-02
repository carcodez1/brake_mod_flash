# File: tests/test_telemetry.py
# Unit tests for telemetry.py – log capture, file writing, timestamp checks
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.0.0

import os
import time
import tempfile
import importlib.util
import pytest

# Assumed location of telemetry module
TELEMETRY_PATH = "scripts/telemetry.py"

@pytest.fixture(scope="module")
def telemetry_module():
    assert os.path.exists(TELEMETRY_PATH), f"Missing: {TELEMETRY_PATH}"
    spec = importlib.util.spec_from_file_location("telemetry", TELEMETRY_PATH)
    telemetry = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(telemetry)
    return telemetry

def test_log_file_written(telemetry_module):
    """Ensure log message writes to the default file."""
    msg = f"Test entry {int(time.time())}"
    telemetry_module.log(msg)

    # Locate the latest file
    log_dir = telemetry_module.LOG_DIR if hasattr(telemetry_module, "LOG_DIR") else "logs"
    log_files = sorted(os.listdir(log_dir), reverse=True)
    assert log_files, "No log files found"

    latest = os.path.join(log_dir, log_files[0])
    with open(latest, "r") as f:
        content = f.read()
        assert msg in content

def test_log_message_timestamp_format(telemetry_module):
    """Check that timestamps in logs are correctly formatted."""
    test_msg = "Timestamp format test"
    telemetry_module.log(test_msg)

    log_dir = telemetry_module.LOG_DIR if hasattr(telemetry_module, "LOG_DIR") else "logs"
    latest = sorted(os.listdir(log_dir), reverse=True)[0]
    with open(os.path.join(log_dir, latest)) as f:
        lines = f.readlines()

    matching = [line for line in lines if test_msg in line]
    assert matching, "Expected log message not found"
    assert matching[0].startswith("["), "Missing timestamp prefix"

def test_multi_line_message_support(telemetry_module):
    """Test that multiline logs are preserved and correctly written."""
    multiline_msg = "MULTILINE\nMESSAGE\nTEST"
    telemetry_module.log(multiline_msg)

    log_dir = telemetry_module.LOG_DIR if hasattr(telemetry_module, "LOG_DIR") else "logs"
    latest = sorted(os.listdir(log_dir), reverse=True)[0]
    with open(os.path.join(log_dir, latest)) as f:
        content = f.read()

    assert "MULTILINE" in content
    assert "MESSAGE" in content
    assert "TEST" in content

def test_log_to_temp_override(telemetry_module):
    """Verify that log path override (if supported) writes elsewhere."""
    if not hasattr(telemetry_module, "log_with_path"):
        pytest.skip("log_with_path() not implemented")

    with tempfile.NamedTemporaryFile(mode="r+", delete=False) as tmp:
        telemetry_module.log_with_path("Test log to temp", tmp.name)
        tmp.seek(0)
        content = tmp.read()
        assert "Test log to temp" in content
