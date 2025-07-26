# File: tests/test_emulator_gui.py
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assigned
# Version: 1.1.1 – Finalized GUI Test Suite

import json
import shutil
import tempfile
from pathlib import Path
import tkinter as tk
import pytest
from unittest.mock import patch, MagicMock, mock_open

from gui.emulator_gui import BrakeFlashEmulator

@pytest.fixture
def test_gui():
    root = tk.Tk()
    app = BrakeFlashEmulator(root)
    yield app
    root.destroy()

@pytest.fixture
def temp_paths(tmp_path):
    config = tmp_path / "gui/config_template.json"
    last = tmp_path / "gui/state/last_config.json"
    preset = tmp_path / "gui/state/presets/test_preset.json"
    yaml_out = tmp_path / "gui/export.yaml"
    return {
        "config": config,
        "last": last,
        "preset": preset,
        "yaml": yaml_out,
        "preset_dir": preset.parent,
    }

# ─────────── CONFIG MODEL ───────────

def test_valid_pattern_extraction(test_gui):
    for row in test_gui.entries:
        row[0].insert(0, "2")
        row[1].insert(0, "150")
        row[2].insert(0, "100")
    pattern = test_gui.extract_config()
    assert len(pattern) == 5
    assert all(step["count"] == 2 for step in pattern)

def test_pattern_rejects_invalid_rows(test_gui):
    test_gui.entries[0][0].insert(0, "abc")
    test_gui.entries[1][0].insert(0, "100")
    test_gui.entries[1][1].insert(0, "50")
    test_gui.entries[1][2].insert(0, "50")
    pattern = test_gui.extract_config()
    assert len(pattern) == 1
    assert pattern[0]["count"] == 100

# ─────────── GUI LOGIC ───────────

def test_clear_all_fields_resets_gui(test_gui):
    test_gui.entries[0][0].insert(0, "1")
    test_gui.entries[0][1].insert(0, "100")
    test_gui.entries[0][2].insert(0, "100")
    test_gui.clear_all()
    assert test_gui.entries[0][0].get() == ""
    assert test_gui.entries[0][1].get() == ""
    assert test_gui.entries[0][2].get() == ""

def test_load_last_config_file(test_gui, tmp_path):
    state_path = tmp_path / "gui/state/last_config.json"
    state_path.parent.mkdir(parents=True, exist_ok=True)
    state_path.write_text(json.dumps({
        "pattern": [{"count": 2, "on": 120, "off": 80}]
    }))
    with patch("gui.emulator_gui.STATE_PATH", state_path):
        test_gui.load_last()
        pattern = test_gui.extract_config()
        assert pattern[0]["on"] == 120

# ─────────── SAVE/LOAD/EXPORT ───────────

def test_save_config_write_failure(test_gui):
    with patch("gui.emulator_gui.CONFIG_PATH.write_text", side_effect=IOError("disk full")), \
         patch("tkinter.messagebox.askyesno", return_value=False), \
         patch("tkinter.messagebox.showerror") as mock_err:
        test_gui.save_config()
        mock_err.assert_called_once()
        assert "disk full" in mock_err.call_args[0][1]

def test_yaml_export_handles_write_error(test_gui):
    for row in test_gui.entries:
        row[0].insert(0, "1")
        row[1].insert(0, "100")
        row[2].insert(0, "100")
    with patch("tkinter.filedialog.asksaveasfilename", return_value="bad.yaml"), \
         patch("builtins.open", mock_open()) as m:
        m.side_effect = IOError("permission denied")
        with patch("tkinter.messagebox.showerror") as mock_err:
            test_gui.export_yaml()
            mock_err.assert_called_once()
            assert "permission denied" in mock_err.call_args[0][1]

def test_preview_metadata_missing_file(test_gui):
    with patch("gui.emulator_gui.CONFIG_PATH.exists", return_value=False), \
         patch("tkinter.messagebox.showwarning") as mock_warn:
        test_gui.preview_metadata()
        mock_warn.assert_called_once()
        assert "No config file" in mock_warn.call_args[0][1]

# ─────────── PRESET / METADATA / RENDER ───────────

def test_load_preset_file(test_gui, temp_paths):
    preset_file = temp_paths["preset"]
    preset_file.parent.mkdir(parents=True, exist_ok=True)
    preset_file.write_text(json.dumps({
        "pattern": [{"count": 2, "on": 100, "off": 100}]
    }))
    with patch("tkinter.filedialog.askopenfilename", return_value=str(preset_file)):
        test_gui.load_preset()
        pattern = test_gui.extract_config()
        assert len(pattern) == 1
        assert pattern[0]["count"] == 2

def test_yaml_export_logic(test_gui, temp_paths):
    for row in test_gui.entries:
        row[0].insert(0, "3")
        row[1].insert(0, "200")
        row[2].insert(0, "100")
    with patch("tkinter.filedialog.asksaveasfilename", return_value=str(temp_paths["yaml"])):
        test_gui.export_yaml()
        assert temp_paths["yaml"].exists()
        assert "version" in temp_paths["yaml"].read_text()

def test_metadata_preview_shows_data(test_gui, tmp_path):
    config_path = tmp_path / "gui/config_template.json"
    config_path.parent.mkdir(parents=True, exist_ok=True)
    config_path.write_text(json.dumps({"metadata": {"config_id": "demo123"}}))
    with patch("gui.emulator_gui.CONFIG_PATH", config_path), \
         patch("tkinter.messagebox.showinfo") as mock_msg:
        test_gui.preview_metadata()
        mock_msg.assert_called_once()
        assert "demo123" in mock_msg.call_args[0][1]

def test_renderer_invokes_script_successfully(test_gui):
    with patch("subprocess.run") as mock_run:
        mock_run.return_value = MagicMock(stdout="Done", returncode=0)
        test_gui.run_renderer()
        mock_run.assert_called_once()
        assert "render_config_to_ino.py" in mock_run.call_args[0][0][1]

def test_renderer_failure_handled(test_gui):
    with patch("subprocess.run", side_effect=Exception("boom")), \
         patch("tkinter.messagebox.showerror") as mock_err:
        test_gui.run_renderer()
        mock_err.assert_called_once()
        assert "boom" in mock_err.call_args[0][1]
