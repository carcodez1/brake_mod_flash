import core.logger as logger
# File: ui/pattern_editor.py
# Purpose: GUI components for pattern editing (manual step entry)
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assigned
# Version: 1.5.0

import tkinter as tk
from tkinter import ttk
from core import state, logger

def create_pattern_editor(root, render_preview_fn):
    frame = ttk.LabelFrame(root, text="Pattern Step Entry")
    frame.pack(fill="x", padx=12, pady=4)

    count_var = tk.IntVar(value=3)
    on_var = tk.IntVar(value=100)
    off_var = tk.IntVar(value=100)

    ttk.Label(frame, text="Count:").grid(row=0, column=0)
    count_entry = ttk.Entry(frame, textvariable=count_var, width=6)
    count_entry.grid(row=0, column=1)

    ttk.Label(frame, text="On (ms):").grid(row=0, column=2)
    on_entry = ttk.Entry(frame, textvariable=on_var, width=6)
    on_entry.grid(row=0, column=3)

    ttk.Label(frame, text="Off (ms):").grid(row=0, column=4)
    off_entry = ttk.Entry(frame, textvariable=off_var, width=6)
    off_entry.grid(row=0, column=5)

    def add_step():
        try:
            count = int(count_var.get())
            on = int(on_var.get())
            off = int(off_var.get())
            state.config_state["pattern"].append({"count": count, "on": on, "off": off})
            render_preview_fn()
            logger.log(f"[+] Added step: {count}x [ON {on}ms / OFF {off}ms]")
        except Exception as e:
            logger.log(f"[!] Invalid pattern step: {e}")

    def clear_pattern():
        state.config_state["pattern"].clear()
        render_preview_fn()
        logger.log("[−] Pattern cleared.")

    ttk.Button(frame, text="Add", command=add_step).grid(row=0, column=6, padx=6)
    ttk.Button(frame, text="Clear", command=clear_pattern).grid(row=0, column=7, padx=6)

    return frame, count_entry, on_entry, off_entry
