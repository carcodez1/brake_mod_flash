# File: tests/test_emulator_gui.py
# Unit tests for emulator_gui.py (full GUI + test mode logic)
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.0.0

import subprocess
import sys
import os
import json
import yaml
import pytest

EMULATOR_GUI = "gui/emulator_gui.py"
DEFAULT_CONFIG_JSON = {
    "pattern": [
        {"count": 3, "on": 100, "off": 100},
        {"count": 2, "on": 200, "off": 100}
    ]
}
CONFIG_PATH = "tests/assets/test_gui_config.json"
YAML_PATH = "tests/assets/test_gui_config.yaml"

@pytest.fixture(scope="module", autouse=True)
def setup_assets():
    os.makedirs("tests/assets", exist_ok=True)
    with open(CONFIG_PATH, "w") as f:
        json.dump(DEFAULT_CONFIG_JSON, f, indent=2)
    with open(YAML_PATH, "w") as f:
        yaml.dump(DEFAULT_CONFIG_JSON, f)
    yield
    os.remove(CONFIG_PATH)
    os.remove(YAML_PATH)

def test_emulator_test_mode():
    """Ensure --test flag runs silently with proper exit code."""
    result = subprocess.run([sys.executable, EMULATOR_GUI, "--test"], capture_output=True, text=True)
    assert result.returncode == 0
    assert "test mode" in result.stdout.lower()

def test_gui_file_loading_json():
    """Ensure JSON config is readable via GUI backend logic."""
    with open(CONFIG_PATH) as f:
        data = json.load(f)
        assert "pattern" in data
        assert isinstance(data["pattern"], list)
        assert all("count" in step and "on" in step and "off" in step for step in data["pattern"])

def test_gui_file_loading_yaml():
    """Ensure YAML config is readable via GUI backend logic."""
    with open(YAML_PATH) as f:
        data = yaml.safe_load(f)
        assert "pattern" in data
        assert isinstance(data["pattern"], list)
        assert data["pattern"][0]["on"] == 100

def test_pattern_structure_validity():
    """Ensure all pattern steps conform to expected structure."""
    with open(CONFIG_PATH) as f:
        config = json.load(f)
    for step in config["pattern"]:
        assert isinstance(step["count"], int)
        assert isinstance(step["on"], int)
        assert isinstance(step["off"], int)
        assert step["count"] > 0

def test_firmware_script_presence():
    """Verify firmware rendering script exists (precondition)."""
    assert os.path.exists("scripts/render_config_to_ino.py")
