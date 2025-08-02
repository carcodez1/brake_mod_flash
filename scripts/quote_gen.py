#!/usr/bin/env python3
"""
scripts/quote_gen.py
Copyright (c) MyGeo LLC
License: Proprietary

Enterprise-grade CLI pricing engine for BrakeFlasher Toolkit.
"""

import json, uuid, hashlib, argparse, datetime, sys
from pathlib import Path

TIERS = json.loads(Path("config/pricing/tiers.json").read_text())["tiers"]
ADDONS = json.loads(Path("config/pricing/addons.json").read_text())["addons"]

def generate_quote(tier_id, addon_ids):
    tier = next((t for t in TIERS if t["id"] == tier_id), None)
    if not tier:
        raise ValueError(f"Invalid tier ID: {tier_id}")

    known_addons = {a["id"]: a for a in ADDONS}
    selected_addons = []
    for aid in addon_ids:
        if aid not in known_addons:
            raise ValueError(f"Unknown addon ID: {aid}")
        selected_addons.append(known_addons[aid])

    total = tier["price_usd"] + sum(a["price_usd"] for a in selected_addons)
    quote = {
        "quote_id": str(uuid.uuid4()),
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "tier": tier,
        "addons": selected_addons,
        "total_usd": total
    }

    encoded = json.dumps(quote, sort_keys=True).encode()
    quote["sha256"] = hashlib.sha256(encoded).hexdigest()

    out_path = Path("output/quotes")
    out_path.mkdir(parents=True, exist_ok=True)
    date = datetime.datetime.utcnow().strftime("%Y-%m-%d")
    file_name = f"{date}_{tier_id}_{quote['quote_id']}.json"
    Path(out_path / file_name).write_text(json.dumps(quote, indent=2))
    print(f"[SUCCESS] Quote saved to: output/quotes/{file_name}")

    return quote

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate BrakeFlasher quote")
    parser.add_argument("tier", help="Tier ID (starter | installer | fleet | oem)")
    parser.add_argument("--addons", nargs="*", default=[], help="Addon IDs")
    args = parser.parse_args()

    try:
        generate_quote(args.tier, args.addons)
    except ValueError as e:
        print(f"[ERROR] {e}")
        sys.exit(1)
