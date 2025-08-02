# File: ui/firmware_info.py
# Purpose: Firmware metadata/status display
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assigned
# Version: 1.5.0

from tkinter import ttk
from core import state

def create_firmware_info_frame(root):
    frame = ttk.LabelFrame(root, text="Firmware Info")
    frame.pack(fill="x", padx=12, pady=4)

    ttk.Label(frame, text="Version:").grid(row=0, column=0, sticky="w")
    ttk.Label(frame, textvariable=state.version_var).grid(row=0, column=1, sticky="w")

    ttk.Label(frame, text="Config Path:").grid(row=1, column=0, sticky="w")
    ttk.Label(frame, textvariable=state.config_path_var).grid(row=1, column=1, sticky="w")

    ttk.Label(frame, text="Firmware Output:").grid(row=2, column=0, sticky="w")
    ttk.Label(frame, textvariable=state.output_path_var).grid(row=2, column=1, sticky="w")

    return frame
