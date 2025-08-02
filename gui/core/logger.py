# File: core/logger.py
# Purpose: Centralized logging for GUI + persistent log file
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assigned
# Version: 1.5.0

import os
from datetime import datetime

LOG_PATH = "logs/last_session.log"
log_widget = None

def log(message: str):
    timestamp = datetime.now().strftime("[%H:%M:%S]")
    line = f"{timestamp} {message}"
    print(line)

    with open(LOG_PATH, "a") as f:
        f.write(line + "\n")

    if log_widget:
        log_widget.insert("end", line + "\n")
        log_widget.see("end")

def attach_widget(widget):
    global log_widget
    log_widget = widget

def clear_log_file():
    if os.path.exists(LOG_PATH):
        os.remove(LOG_PATH)
