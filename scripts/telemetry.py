# File: scripts/telemetry.py
# Logging utility for BrakeFlasher Toolkit
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.0.0

import os
from datetime import datetime

LOG_DIR = "logs"
os.makedirs(LOG_DIR, exist_ok=True)

def _log_path():
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    return os.path.join(LOG_DIR, f"firmware_log_{ts}.log")

_current_log_path = _log_path()

def log(message: str):
    """Log message to current session log file with timestamp."""
    timestamp = datetime.now().strftime("[%H:%M:%S]")
    full = f"{timestamp} {message}"
    with open(_current_log_path, "a") as f:
        f.write(full + "\n")
    print(full)

def log_with_path(message: str, filepath: str):
    """Log a message directly to a given path."""
    timestamp = datetime.now().strftime("[%H:%M:%S]")
    full = f"{timestamp} {message}"
    with open(filepath, "a") as f:
        f.write(full + "\n")
    print(full)
