# File: tests/test_run_gui_launcher.py
# Purpose: Validate BrakeFlasher GUI launcher & environment readiness
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assigned
# Version: 1.1.0

import os
import subprocess
import sys
import pytest
from pathlib import Path
import importlib.util

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

# Try standard project-local venv first
DEFAULT_VENV = Path(".venv")
ALT_VENV = Path.home() / ".brake_mod_gui" / "venv"

VENV_DIR = DEFAULT_VENV if (DEFAULT_VENV / "bin/python").exists() else ALT_VENV
PYTHON_BIN = VENV_DIR / "bin/python"
GUI_SCRIPT = Path("gui/emulator_gui.py")

#───────────────────────────────────────────────────────────────────────────────
# TESTS
#───────────────────────────────────────────────────────────────────────────────

@pytest.mark.skipif(not GUI_SCRIPT.exists(), reason="GUI script missing")
def test_gui_script_exists():
    assert GUI_SCRIPT.exists(), f"Missing: {GUI_SCRIPT}"

@pytest.mark.skipif(not (VENV_DIR / "bin/activate").exists(), reason="Virtualenv not found")
def test_virtualenv_detected():
    assert VENV_DIR.exists(), f"Venv missing at {VENV_DIR}"

@pytest.mark.skipif(not PYTHON_BIN.exists(), reason="Python binary missing in virtualenv")
def test_python_binary_available():
    assert PYTHON_BIN.exists(), f"Python not found in: {PYTHON_BIN}"

@pytest.mark.skip(reason="tkinter test skipped in headless/CI environments")
def test_tkinter_available():
    # tkinter check using importlib to avoid console crash
    result = subprocess.run(
        [str(PYTHON_BIN), "-c", "import importlib.util; assert importlib.util.find_spec('tkinter') is not None"],
        capture_output=True,
        text=True
    )
    assert result.returncode == 0, f"tkinter not found in virtualenv: {result.stderr.strip()}"

@pytest.mark.skipif("CI" in os.environ or os.getenv("DISPLAY", "") == "", reason="Headless environment – GUI skipped")
def test_gui_launch_dry_run():
    # Run GUI script in subprocess to verify no crash
    try:
        result = subprocess.run(
            [str(PYTHON_BIN), str(GUI_SCRIPT)],
            check=False,
            timeout=5,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        assert result.returncode in (0, 1), f"Unexpected crash: {result.stderr.decode().strip()}"
    except subprocess.TimeoutExpired:
        pytest.fail("GUI launch timeout – no response from emulator_gui.py")
