import core.logger as logger
# .last_config.json autosave/load logic
import json
import os
from core.logger import log
from tkinter import messagebox

LAST_CONFIG_PATH = "gui/state/.last_config.json"

def save_last_config(data: dict):
    try:
        with open(LAST_CONFIG_PATH, "w") as f:
            json.dump(data, f, indent=2)
        log(f"[✓] Saved .last_config.json for session recovery.")
    except Exception as e:
        log(f"[!] Failed to save .last_config.json: {e}")

def load_last_config():
    try:
        if os.path.exists(LAST_CONFIG_PATH):
            with open(LAST_CONFIG_PATH, "r") as f:
                return json.load(f)
    except Exception as e:
        log(f"[!] Failed to load .last_config.json: {e}")
    return None

def add_pattern_step(count, on, off):
    from core.state import config_state
    config_state["pattern"].append({
        "count": int(count),
        "on": int(on),
        "off": int(off)
    })

def clear_pattern():
    from core.state import config_state
    config_state["pattern"].clear()
