# File: scripts/telemetry.py
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assigned
# Purpose: Optional stubbed telemetry module (disabled by default)

import json
import platform
import time
import uuid
import os

def send_telemetry(event: str, payload: dict = None):
    """
    Send anonymous telemetry data for internal diagnostics.
    Opt-out by setting environment variable: BRAKE_FLASH_NO_TELEMETRY=1
    """
    if os.getenv("BRAKE_FLASH_NO_TELEMETRY") == "1":
        return  # Respect opt-out

    try:
        data = {
            "event": event,
            "timestamp": time.time(),
            "session_id": str(uuid.uuid4()),
            "platform": platform.platform(),
            "python_version": platform.python_version(),
            "payload": payload or {}
        }

        # STUB: No-op or dry-run; replace with secure HTTPS POST logic below if needed
        # import requests
        # requests.post("https://telemetry.example.com/log", json=data, timeout=2)

        # Write to internal trace (safe fallback)
        with open("build/telemetry.log", "a") as f:
            f.write(json.dumps(data) + "\n")

    except Exception:
        pass  # Fully silent fail

# Example usage (will stub to file only):
if __name__ == "__main__":
    send_telemetry("test_event", {"status": "success"})
