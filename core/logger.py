import core.logger as logger
logger.py
# File: core/logger.py
# Purpose: Centralized logger with GUI + console output (color-coded)
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.1.0

import datetime
import sys
import tkinter as tk

log_widget = None  # Injected by GUI
log_file = None    # Optional: future persistent log path


# ─────────────────────────────────────────────
# Timestamp Utility
# ─────────────────────────────────────────────
def timestamp():
    return datetime.datetime.now().strftime("%H:%M:%S")


# ─────────────────────────────────────────────
# Console Color Codes
# ─────────────────────────────────────────────
class Colors:
    RESET = "\033[0m"
    GRAY = "\033[90m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    CYAN = "\033[96m"

def supports_color():
    return sys.stdout.isatty()


# ─────────────────────────────────────────────
# Log Dispatcher
# ─────────────────────────────────────────────
def log(msg, level="INFO"):
    ts = timestamp()
    formatted = f"[{ts}] [{level}] {msg}"

    # Console output
    if supports_color():
        color = {
            "INFO": Colors.GRAY,
            "OK": Colors.GREEN,
            "WARN": Colors.YELLOW,
            "ERROR": Colors.RED,
            "TRACE": Colors.CYAN
        }.get(level, Colors.GRAY)
        print(f"{color}{formatted}{Colors.RESET}")
    else:
        print(formatted)

    # GUI output
    if log_widget:
        tag = level.lower()
        log_widget.insert("end", f"{formatted}\n", tag)
        log_widget.see("end")


# ─────────────────────────────────────────────
# GUI Log Formatter (called by GUI on init)
# ─────────────────────────────────────────────
def setup_gui_log_tags(text_widget: tk.Text):
    global log_widget
    log_widget = text_widget
    log_widget.tag_config("info", foreground="#666666")
    log_widget.tag_config("ok", foreground="#228B22")      # forest green
    log_widget.tag_config("warn", foreground="#DAA520")    # goldenrod
    log_widget.tag_config("error", foreground="#B22222")   # firebrick
    log_widget.tag_config("trace", foreground="#1E90FF")   # dodgerblue
