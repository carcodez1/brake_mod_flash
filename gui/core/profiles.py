import core.logger as logger
# File: core/profiles.py
# Purpose: Load and apply predefined flash profiles
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assigned
# Version: 1.5.0

import json
from core import state, logger

PROFILE_PATH = "docs/flash_pattern_profiles.json"

def load_profiles():
    try:
        with open(PROFILE_PATH, "r") as f:
            return json.load(f)
    except Exception as e:
        logger.log(f"[!] Failed to load profiles: {e}")
        return {}

def apply_profile(profile_name, profile_data, render_preview_fn):
    profile = profile_data.get(profile_name)
    if not profile:
        logger.log(f"[!] Unknown profile: {profile_name}")
        return

    state.config_state["pattern"] = [{
        "count": profile["count"],
        "on": profile["on_ms"],
        "off": profile["off_ms"]
    }]

    state.compliance_var.set(profile.get("compliance_level", "unknown"))
    state.pattern_mode_var.set(profile_name)
    render_preview_fn()
