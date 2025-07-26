#!/usr/bin/env python3
# File: gui/emulator_gui.py
# Author: Jeffrey Plewak
# Version: 1.3.0
# License: Proprietary – NDA / IP Assignment

import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import json, subprocess, sys
from pathlib import Path
from datetime import datetime
import yaml

CONFIG_PATH = Path("gui/config_template.json")
STATE_PATH = Path("gui/state/last_config.json")
PRESET_DIR = Path("gui/state/presets")
LOG_FILE = Path("gui/logs/emulator.log")
PRESET_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE.parent.mkdir(parents=True, exist_ok=True)

def log(msg):
    timestamp = datetime.now().isoformat(timespec="seconds")
    LOG_FILE.write_text(f"[{timestamp}] {msg}\n", encoding="utf-8", errors="ignore") if not LOG_FILE.exists() else LOG_FILE.write_text(LOG_FILE.read_text() + f"[{timestamp}] {msg}\n")

class BrakeFlashEmulator:
    def __init__(self, root):
        self.root = root
        self.root.title("Brake Light Pattern Configurator")
        self.pattern = []
        self.setup_ui()

    def setup_ui(self):
        self.entries = []
        frame = ttk.Frame(self.root, padding="10")
        frame.grid(row=0, column=0, sticky="nsew")

        ttk.Label(frame, text="Count").grid(row=0, column=0)
        ttk.Label(frame, text="On (ms)").grid(row=0, column=1)
        ttk.Label(frame, text="Off (ms)").grid(row=0, column=2)

        for i in range(5):
            row = []
            for j in range(3):
                e = ttk.Entry(frame, width=8)
                e.grid(row=i+1, column=j, padx=2, pady=2)
                row.append(e)
            self.entries.append(row)

        button_frame = ttk.Frame(self.root, padding="10")
        button_frame.grid(row=1, column=0, sticky="ew")
        ttk.Button(button_frame, text="Save Config", command=self.save_config).pack(side="left")
        ttk.Button(button_frame, text="Load Last", command=self.load_last).pack(side="left")
        ttk.Button(button_frame, text="Load Preset", command=self.load_preset).pack(side="left")
        ttk.Button(button_frame, text="Export YAML", command=self.export_yaml).pack(side="left")
        ttk.Button(button_frame, text="View Metadata", command=self.preview_metadata).pack(side="left")
        ttk.Button(button_frame, text="Clear", command=self.clear_all).pack(side="left")
        ttk.Button(button_frame, text="Exit", command=self.root.quit).pack(side="right")

        self.status = tk.StringVar()
        ttk.Label(self.root, textvariable=self.status, relief="sunken", anchor="w", padding=4).grid(row=2, column=0, sticky="ew")
        self.update_status("Ready")

        if STATE_PATH.exists():
            self.load_last()

    def update_status(self, msg):
        timestamp = datetime.now().isoformat(timespec="seconds")
        self.status.set(f"{timestamp} – {msg}")
        log(msg)

    def clear_all(self):
        for row in self.entries:
            for e in row:
                e.delete(0, tk.END)
        self.update_status("Cleared all fields")

    def extract_config(self):
        config = []
        for row in self.entries:
            try:
                count = int(float(row[0].get()))
                on = int(float(row[1].get()))
                off = int(float(row[2].get()))
                if not (1 <= count <= 20 and 0 <= on <= 2000 and 0 <= off <= 2000):
                    continue
                config.append({"count": count, "on": on, "off": off})
            except Exception:
                continue
        if len(config) > 10:
            messagebox.showwarning("Pattern Too Long", "Maximum 10 steps recommended for microcontroller safety.")
        return config

    def save_config(self):
        pattern = self.extract_config()
        if not pattern:
            messagebox.showerror("Error", "No valid pattern entered.")
            return
        config_id = f"cfg-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
        data = {
            "version": "1.3.0",
            "generated": datetime.utcnow().isoformat() + "Z",
            "pattern": pattern,
            "metadata": {"config_id": config_id}
        }
        try:
            CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
            CONFIG_PATH.write_text(json.dumps(data, indent=2), encoding="utf-8")
            STATE_PATH.write_text(json.dumps(data, indent=2), encoding="utf-8")
            self.update_status(f"Config saved: {CONFIG_PATH}")
            messagebox.showinfo("Saved", f"Configuration saved to:\n{CONFIG_PATH}")
        except Exception as e:
            messagebox.showerror("Save Error", str(e))
            self.update_status("Save failed")

        if messagebox.askyesno("Run Renderer", "Render firmware now?"):
            self.run_renderer()

    def run_renderer(self):
        try:
            result = subprocess.run(
                ["python3", "scripts/render_config_to_ino.py"],
                check=True,
                capture_output=True,
                text=True
            )
            self.update_status("Firmware generated successfully")
            messagebox.showinfo("Renderer Output", result.stdout)
        except subprocess.CalledProcessError as e:
            messagebox.showerror("Renderer Error", e.stderr or str(e))
            self.update_status("Firmware rendering failed")

    def load_last(self):
        if not STATE_PATH.exists():
            messagebox.showwarning("Not Found", "No previous configuration found.")
            return
        try:
            self.clear_all()
            data = json.loads(STATE_PATH.read_text(encoding="utf-8"))
            for i, step in enumerate(data.get("pattern", [])):
                if i < len(self.entries):
                    self.entries[i][0].insert(0, step.get("count", ""))
                    self.entries[i][1].insert(0, step.get("on", ""))
                    self.entries[i][2].insert(0, step.get("off", ""))
            self.update_status("Last config loaded")
        except Exception as e:
            messagebox.showerror("Load Error", str(e))

    def load_preset(self):
        file = filedialog.askopenfilename(initialdir=PRESET_DIR, filetypes=[("JSON Files", "*.json")])
        if not file:
            return
        try:
            self.clear_all()
            data = json.loads(Path(file).read_text(encoding="utf-8"))
            for i, step in enumerate(data.get("pattern", [])):
                if i < len(self.entries):
                    self.entries[i][0].insert(0, step.get("count", ""))
                    self.entries[i][1].insert(0, step.get("on", ""))
                    self.entries[i][2].insert(0, step.get("off", ""))
            self.update_status(f"Preset loaded: {file}")
        except Exception as e:
            messagebox.showerror("Preset Load Error", str(e))

    def export_yaml(self):
        pattern = self.extract_config()
        if not pattern:
            messagebox.showerror("Error", "No valid pattern entered.")
            return
        out_path = filedialog.asksaveasfilename(defaultextension=".yaml", filetypes=[("YAML", "*.yaml")])
        if not out_path:
            return
        config_id = f"cfg-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
        data = {
            "version": "1.3.0",
            "generated": datetime.utcnow().isoformat() + "Z",
            "pattern": pattern,
            "metadata": {"config_id": config_id}
        }
        try:
            with open(out_path, "w") as f:
                yaml.dump(data, f)
            self.update_status(f"YAML exported: {out_path}")
        except Exception as e:
            messagebox.showerror("Export Error", str(e))

    def preview_metadata(self):
        try:
            if CONFIG_PATH.exists():
                data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
                text = json.dumps(data.get("metadata", {}), indent=2)
                messagebox.showinfo("Metadata Preview", text)
            else:
                messagebox.showwarning("Missing", "No config file found.")
        except Exception as e:
            messagebox.showerror("Metadata Error", str(e))

# ───────── ENTRYPOINT ─────────
def check_dependencies():
    try:
        import tkinter, yaml
    except ImportError as e:
        sys.exit(f"[✗] Missing dependency: {e.name} – install it first.")

def main():
    check_dependencies()
    root = tk.Tk()
    app = BrakeFlashEmulator(root)
    root.mainloop()

if __name__ == "__main__":
    main()
