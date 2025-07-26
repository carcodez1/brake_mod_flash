# emulator_gui.py
# Production Brake Pattern Emulator with Absolute Paths + YAML Config + Schema Validation
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assigned
# Version: loaded from settings.yaml
# Date: 2025-07-26

import json
import yaml
import logging
import os
import sys
import tkinter as tk
from tkinter import ttk, messagebox
from datetime import datetime
from threading import Thread
import time
import argparse
from jsonschema import validate, ValidationError

# Load YAML settings
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
SETTINGS_PATH = os.path.join(ROOT_DIR, "../config/settings.yaml")
SCHEMA_PATH = os.path.join(ROOT_DIR, "../config/input_schema.json")

with open(SETTINGS_PATH, "r") as f:
    SETTINGS = yaml.safe_load(f)

with open(SCHEMA_PATH, "r") as f:
    SCHEMA = json.load(f)

APP_VERSION = SETTINGS["version"]
CONFIG_ID = SETTINGS["config_id"]
CONFIG_PATH = os.path.abspath(os.path.join(ROOT_DIR, "../" + SETTINGS["config_path"]))
LOG_DIR = os.path.abspath(os.path.join(ROOT_DIR, "../" + SETTINGS["log_dir"]))
SCENARIO_DIR = os.path.abspath(os.path.join(ROOT_DIR, "../" + SETTINGS["scenario_dir"]))
DELAY_CAP_MS = 2000

# Ensure paths exist
os.makedirs(LOG_DIR, exist_ok=True)
os.makedirs(SCENARIO_DIR, exist_ok=True)

# Rolling log setup
LOG_FILE = os.path.join(LOG_DIR, f"{datetime.today().strftime('%Y-%m-%d')}.log")
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s.%(msecs)03d [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

class FlashEmulatorGUI:
    def __init__(self, master):
        self.master = master
        self.master.title("Brake Flasher Emulator")
        self.canvas = tk.Canvas(master, width=400, height=200, bg="black")
        self.canvas.pack(pady=10)
        self.flash_box = self.canvas.create_oval(150, 50, 250, 150, fill="gray")

        self.pattern = self.load_config(CONFIG_PATH)
        self.playing = False
        self.event_log = []

        btn_frame = ttk.Frame(master)
        btn_frame.pack(pady=10)

        ttk.Button(btn_frame, text="▶ Run Pattern", command=self.run_pattern).grid(row=0, column=0, padx=5)
        ttk.Button(btn_frame, text="⟳ Reload Config", command=self.reload_config).grid(row=0, column=1, padx=5)
        ttk.Button(btn_frame, text="💾 Save Scenario", command=self.save_scenario).grid(row=0, column=2, padx=5)
        ttk.Button(btn_frame, text="📤 Export Trace", command=self.export_event_trace).grid(row=0, column=3, padx=5)

        self.status_var = tk.StringVar(value="Idle")
        ttk.Label(master, textvariable=self.status_var).pack()

        footer_text = f"BrakeFlasher PRO v{APP_VERSION} | Config ID: {CONFIG_ID}"
        ttk.Label(master, text=footer_text, font=("Arial", 8)).pack(side=tk.BOTTOM, pady=4)

        logging.info("Emulator initialized")

    def load_config(self, path):
        try:
            with open(path, "r") as f:
                cfg = json.load(f)
            validate(instance=cfg, schema=SCHEMA)
            pattern = cfg["pattern"]
            logging.info(f"Loaded config: {path}")
            return pattern
        except (json.JSONDecodeError, ValidationError) as e:
            logging.error(f"Invalid config: {e}")
            messagebox.showerror("Validation Error", f"Config failed schema validation:\n{e}")
            return []

    def reload_config(self):
        self.pattern = self.load_config(CONFIG_PATH)
        self.status_var.set(f"Config Reloaded: {os.path.basename(CONFIG_PATH)}")

    def run_pattern(self):
        if self.playing:
            logging.warning("Pattern already running")
            return
        thread = Thread(target=self._run)
        thread.start()

    def _run(self):
        self.playing = True
        self.status_var.set("Running...")
        self.event_log.clear()
        for step in self.pattern:
            count = step.get("count", 1)
            on = min(step.get("on", 100), DELAY_CAP_MS)
            off = min(step.get("off", 100), DELAY_CAP_MS)
            for _ in range(count):
                self._flash_on(on)
                self._flash_off(off)
        self.canvas.itemconfig(self.flash_box, fill="red")
        self.master.update()
        self.status_var.set("Complete")
        logging.info("Pattern complete")
        self.export_event_trace()
        self.playing = False

    def _flash_on(self, duration):
        self.canvas.itemconfig(self.flash_box, fill="red")
        self.master.update()
        time.sleep(duration / 1000.0)
        self.event_log.append({"ts": time.time(), "state": "ON", "duration": duration})

    def _flash_off(self, duration):
        self.canvas.itemconfig(self.flash_box, fill="gray")
        self.master.update()
        time.sleep(duration / 1000.0)
        self.event_log.append({"ts": time.time(), "state": "OFF", "duration": duration})

    def save_scenario(self):
        now = datetime.utcnow().strftime("%Y%m%dT%H%M%S")
        scenario_file = os.path.join(SCENARIO_DIR, f"scenario_{now}.json")
        config = {
            "version": APP_VERSION,
            "generated": datetime.utcnow().isoformat() + "Z",
            "pattern": self.pattern,
            "metadata": {
                "config_id": CONFIG_ID,
                "source": "emulator_gui",
                "legal_notice": "Proprietary. NDA/IP assigned."
            }
        }
        with open(scenario_file, "w") as f:
            json.dump(config, f, indent=2)
        logging.info(f"Saved scenario: {scenario_file}")
        self.status_var.set(f"Saved: {os.path.basename(scenario_file)}")

    def export_event_trace(self):
        now = datetime.utcnow().strftime("%Y%m%dT%H%M%S")
        path = os.path.join(LOG_DIR, f"event_trace_{now}.json")
        with open(path, "w") as f:
            json.dump(self.event_log, f, indent=2)
        logging.info(f"Trace exported: {path}")

def run_headless():
    try:
        with open(CONFIG_PATH, "r") as f:
            cfg = json.load(f)
        validate(instance=cfg, schema=SCHEMA)
        pattern = cfg["pattern"]
        for step in pattern:
            count = step.get("count", 1)
            on = min(step.get("on", 100), DELAY_CAP_MS)
            off = min(step.get("off", 100), DELAY_CAP_MS)
            for _ in range(count):
                time.sleep(on / 1000.0)
                time.sleep(off / 1000.0)
        logging.info("Headless run complete")
    except Exception as e:
        logging.error(f"Headless execution failed: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--headless", action="store_true", help="Run without GUI")
    args = parser.parse_args()

    if args.headless:
        run_headless()
    else:
        root = tk.Tk()
        app = FlashEmulatorGUI(root)
        root.mainloop()
