import core.logger as logger
#!/usr/bin/env python3
# GUI Entry Point – Enterprise Modular v1.5.0+

import tkinter as tk
from tkinter import ttk
from core import logger, state, profiles
from ui import pattern_editor, preview, enterprise_toggles, buttons, recovery

def gui_main():
    logger.log("[✓] Starting GUI")

    root = tk.Tk()
    root.title("BrakeFlasher Toolkit – GUI v1.5.0")

    # Pattern mode dropdown
    mode_frame = ttk.LabelFrame(root, text="Pattern Mode")
    mode_frame.pack(fill="x", padx=12, pady=4)

    profiles_map = profiles.load_pattern_profiles()
    pattern_mode = ttk.Combobox(mode_frame, textvariable=state.pattern_mode_var,
                                 values=list(profiles_map.keys()) + ["custom"],
                                 state="readonly", width=20)
    pattern_mode.grid(row=0, column=1, padx=6)

    ttk.Label(mode_frame, text="Mode:").grid(row=0, column=0)
    ttk.Label(mode_frame, text="Compliance:").grid(row=0, column=2)
    ttk.Label(mode_frame, textvariable=state.compliance_var).grid(row=0, column=3)

    def on_mode_selected(event=None):
        mode = state.pattern_mode_var.get()
        if mode == "custom":
            return
        profile = profiles_map.get(mode)
        if not profile:
            logger.log(f"[!] Invalid mode selected: {mode}")
            return
        profiles.apply_profile_to_config(profile, state.config_state, state.compliance_var)
        preview.render_preview(state.config_state, preview_widget, state.intent_var, state.pattern_mode_var, logger.log)

    pattern_mode.bind("<<ComboboxSelected>>", on_mode_selected)

    # Pattern editor
    count_var = tk.IntVar(value=3)
    on_var = tk.IntVar(value=100)
    off_var = tk.IntVar(value=100)
    editor_frame = pattern_editor.create_pattern_editor(root, count_var, on_var, off_var)
    editor_frame.pack(fill="x", padx=12, pady=4)

    # Flash intent banner
    ttk.Label(root, textvariable=state.intent_var, foreground="darkgreen", font=("Arial", 10, "bold")).pack(padx=12, pady=4)

    # Pattern preview
    preview_widget = preview.create_preview(root)

    # Button bar
    def load_config():
        from tkinter import filedialog, messagebox
        import json, os
        path = filedialog.askopenfilename(filetypes=[("JSON or YAML", "*.json *.yaml")])
        if not path:
            return
        with open(path, "r") as f:
            data = json.load(f)
        if "pattern" not in data:
            messagebox.showerror("Invalid", "Missing pattern.")
            return
        state.config_path_var.set(path)
        state.config_state["pattern"] = data["pattern"]
        state.pattern_mode_var.set(data.get("pattern_mode", "custom"))
        state.compliance_var.set(data.get("compliance_level", "unknown"))
        recovery.save_last_config(data)
        preview.render_preview(state.config_state, preview_widget, state.intent_var, state.pattern_mode_var, logger.log)

    def save_config():
        from tkinter import filedialog
        import json
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
        from tkinter import filedialog
        import json
        path = filedialog.asksaveasfilename(defaultextension=".trace.json", filetypes=[("Trace JSON", "*.json")])
        if not path:
            return
        with open(path, "w") as f:
            json.dump(state.trace_output, f, indent=2)
        logger.log(f"Exported trace: {path}")

    buttons.create_button_panel(root, load_config, save_config, export_trace).pack(fill="x", padx=12, pady=4)

    # Enterprise Toggles (disabled)
    enterprise_toggles.create_enterprise_toggles(root).pack(fill="x", padx=12, pady=4)

    # Log output
    log_frame = ttk.LabelFrame(root, text="Logs")
    log_frame.pack(fill="both", expand=True, padx=12, pady=6)
    logger.log_widget = tk.Text(log_frame, height=10, wrap="none", bg="#f4f4f4")
    logger.setup_gui_log_tags(logger.log_widget)
    logger.log_widget.pack(fill="both", expand=True)

    root.mainloop()

if __name__ == "__main__":
    gui_main()
