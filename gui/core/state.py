# File: core/state.py
# Purpose: Global state variables for GUI and firmware coordination
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assigned
# Version: 1.5.0

import tkinter as tk

# Active configuration (loaded or built)
config_state = {
    "pattern": []
}

# Rendered trace preview (used by export + build)
trace_output = []

# GUI dynamic variables (bound to ttk.Label, etc.)
def init_vars(root):
    global version_var, config_path_var, output_path_var, pattern_mode_var, compliance_var
    version_var = tk.StringVar(master=root, value="–")
    config_path_var = tk.StringVar(master=root, value="–")
    output_path_var = tk.StringVar(master=root, value="–")
    pattern_mode_var = tk.StringVar(master=root, value="custom")
    compliance_var = tk.StringVar(master=root, value="–")
