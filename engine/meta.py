"""Module: meta - Metadata utilities"""

import json
from pathlib import Path

def get_version_info():
    version_file = Path("firmware/metadata/version.json")
    if not version_file.exists():
        return "Version file not found"
    return json.loads(version_file.read_text()).get("version", "unknown")
