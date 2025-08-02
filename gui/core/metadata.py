import core.logger as logger
import json
import os
import tkinter as tk
from tkinter import ttk, messagebox
from .logger import log

LAST_META_PATH = "gui/state/.last_metadata.json"

def edit_metadata_popup():
    def save_meta():
        data = {
            "version": version_var.get(),
            "vehicle": vehicle_var.get(),
            "author": author_var.get(),
            "notes": notes_var.get()
        }
        with open(LAST_META_PATH, "w") as f:
            json.dump(data, f, indent=2)
        messagebox.showinfo("Saved", "Metadata saved.")
        meta_window.destroy()
        log("[✓] Saved updated metadata for next build.")

    existing = {}
    if os.path.exists(LAST_META_PATH):
        try:
            with open(LAST_META_PATH, "r") as f:
                existing = json.load(f)
        except Exception:
            pass

    meta_window = tk.Toplevel()
    meta_window.title("Edit Metadata")

    vehicle_var = tk.StringVar(value=existing.get("vehicle", ""))
    version_var = tk.StringVar(value=existing.get("version", "1.5.0"))
    author_var = tk.StringVar(value=existing.get("author", ""))
    notes_var = tk.StringVar(value=existing.get("notes", ""))

    ttk.Label(meta_window, text="Version:").grid(row=0, column=0, sticky="w")
    ttk.Entry(meta_window, textvariable=version_var).grid(row=0, column=1)

    ttk.Label(meta_window, text="Vehicle:").grid(row=1, column=0, sticky="w")
    ttk.Entry(meta_window, textvariable=vehicle_var).grid(row=1, column=1)

    ttk.Label(meta_window, text="Author:").grid(row=2, column=0, sticky="w")
    ttk.Entry(meta_window, textvariable=author_var).grid(row=2, column=1)

    ttk.Label(meta_window, text="Notes:").grid(row=3, column=0, sticky="nw")
    ttk.Entry(meta_window, textvariable=notes_var, width=40).grid(row=3, column=1, pady=4)

    ttk.Button(meta_window, text="Save", command=save_meta).grid(row=4, column=0, columnspan=2, pady=6)
