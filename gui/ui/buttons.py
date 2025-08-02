import core.logger as logger
# Load, Save, Build, Export, Edit Metadata buttons
# File: ui/buttons.py
# Purpose: GUI buttons for config load/save/build/export and log restore
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assigned
# Version: 1.5.0

import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import json, os, subprocess
from datetime import datetime
from core import logger, state, recovery, firmware, hash_utils

def restore_last_log(log_widget):
    try:
        with open("logs/last_session.log", "r") as f:
            contents = f.read()
        log_widget.delete("1.0", tk.END)
        log_widget.insert(tk.END, contents)
        log_widget.see(tk.END)
        logger.log("[✓] Restored last session log.")
    except Exception as e:
        logger.log(f"[!] Failed to restore last log: {e}")

def load_config():
    path = filedialog.askopenfilename(filetypes=[("JSON or YAML", "*.json *.yaml")])
    if not path:
        return
    try:
        with open(path, "r") as f:
            data = json.load(f)
        if "pattern" not in data:
            messagebox.showerror("Invalid Config", "Missing 'pattern' key.")
            return
        state.config_state["pattern"] = data["pattern"]
        state.pattern_mode_var.set(data.get("pattern_mode", "custom"))
        state.compliance_var.set(data.get("compliance_level", "unknown"))
        state.config_path_var.set(path)
        recovery.save_last_config(data)
        logger.log(f"[✓] Loaded configuration: {path}")
    except Exception as e:
        logger.log(f"[!] Failed to load config: {e}")
        messagebox.showerror("Error", str(e))

def save_config():
    path = filedialog.asksaveasfilename(defaultextension=".json", filetypes=[("JSON", "*.json")])
    if not path:
        return
    output = {
        "pattern_mode": state.pattern_mode_var.get(),
        "compliance_level": state.compliance_var.get(),
        "pattern": state.config_state["pattern"],
        "version": "1.5.0"
    }
    with open(path, "w") as f:
        json.dump(output, f, indent=2)
    state.config_path_var.set(path)
    recovery.save_last_config(output)
    logger.log(f"[✓] Saved configuration: {path}")

def export_trace():
    path = filedialog.asksaveasfilename(defaultextension=".trace.json", filetypes=[("Trace JSON", "*.json")])
    if not path:
        return
    with open(path, "w") as f:
        json.dump(state.trace_output, f, indent=2)
    logger.log(f"[✓] Exported trace: {path}")

def build_firmware():
    if not state.config_path_var.get() or not os.path.isfile(state.config_path_var.get()):
        messagebox.showerror("Missing Config", "Save or load a config before building.")
        return
    try:
        version, when = firmware.generate_firmware(
            state.config_path_var.get(),
            state.FIRMWARE_OUT,
            state.FIRMWARE_META,
            state.SCHEMA_PATH
        )
        state.version_var.set(f"{version} @ {when}")
        state.output_path_var.set(state.FIRMWARE_OUT)
        logger.log(f"[✓] Firmware built: v{version}")
        messagebox.showinfo("Build Success", f"Firmware built.\nVersion: {version}\nGenerated: {when}")
    except Exception as e:
        logger.log(f"[!] Firmware build failed: {e}")
        messagebox.showerror("Build Failed", str(e))

def create_button_panel(root, load_cb, save_cb, trace_cb):
    frame = ttk.Frame(root)
    ttk.Button(frame, text="Load Config", command=load_cb).grid(row=0, column=0, padx=4)
    ttk.Button(frame, text="Save Config", command=save_cb).grid(row=0, column=1, padx=4)
    ttk.Button(frame, text="Build Firmware", command=build_firmware).grid(row=0, column=2, padx=4)
    ttk.Button(frame, text="Export Trace", command=trace_cb).grid(row=0, column=3, padx=4)
    ttk.Button(frame, text="Restore Last Log", command=lambda: restore_last_log(logger.log_widget)).grid(row=0, column=4, padx=4)
    return frame
