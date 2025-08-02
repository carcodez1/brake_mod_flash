# File: ui/preview.py
# Purpose: Flash pattern preview display area
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assigned
# Version: 1.5.0

import tkinter as tk
from tkinter import ttk
from core import state

def create_preview_area(root):
    frame = ttk.LabelFrame(root, text="Pattern Preview")
    frame.pack(fill="x", padx=12, pady=4)
    preview = tk.Text(frame, height=8, width=80, bg="#f8f8f8")
    preview.pack(fill="x")
    return preview

def render_preview(preview_widget):
    state.trace_output.clear()
    preview_widget.delete("1.0", tk.END)
    total_steps = 0

    for idx, step in enumerate(state.config_state["pattern"]):
        desc = f"Step {idx+1}: {step['count']}x [ON {step['on']}ms / OFF {step['off']}ms]"
        preview_widget.insert(tk.END, desc + "\n")
        state.trace_output.append(step)
        total_steps += step["count"]

    state.intent_var.set(f"[✓] Ready to Flash – Mode: {state.pattern_mode_var.get()} | Steps: {total_steps}")
