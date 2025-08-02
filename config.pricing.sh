#!/usr/bin/env bash
# =============================================================================
# Script: bootstrap_pricing_module.sh
# Purpose: Scaffold pricing engine for BrakeFlasher Toolkit (Enterprise Grade)
# Author: MyGeo LLC
# License: Proprietary, Internal Use Only
# =============================================================================

set -euo pipefail
# Uncomment for full trace
# set -x

echo "======================================================================"
echo "🚀 Bootstrapping Pricing Module for BrakeFlasher Toolkit"
echo "======================================================================"

# ------------------------------ PATH SETUP ------------------------------
ROOT_DIR="$(pwd)"
CONFIG_DIR="$ROOT_DIR/config/pricing"
SCRIPT_DIR="$ROOT_DIR/scripts"
TESTS_DIR="$ROOT_DIR/tests"
OUTPUT_DIR="$ROOT_DIR/output/quotes"

echo "[INFO] Creating pricing directory at: $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"
echo "[INFO] Creating script directory at: $SCRIPT_DIR"
mkdir -p "$SCRIPT_DIR"
echo "[INFO] Creating test directory at: $TESTS_DIR"
mkdir -p "$TESTS_DIR"
echo "[INFO] Creating output directory at: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# --------------------------- FILE: tiers.json ---------------------------
TIERS_FILE="$CONFIG_DIR/tiers.json"
echo "[WRITE] Generating $TIERS_FILE"
cat > "$TIERS_FILE" << 'EOF'
{
  "_meta": "Defines license tiers with pricing and feature inclusion.",
  "tiers": [
    {
      "id": "starter",
      "name": "Tier 1 – Starter Kit",
      "price_usd": 179,
      "vin_limit": 1,
      "includes": ["CLI access", "1 pattern", "No GUI", "No tools"]
    },
    {
      "id": "installer",
      "name": "Tier 2 – Installer License",
      "price_usd": 1490,
      "vin_limit": 25,
      "includes": ["CLI + GUI", "25 patterns", "Emulator", "Delivery ZIP"]
    },
    {
      "id": "fleet",
      "name": "Tier 3 – Internal Fleet License",
      "price_usd": 4900,
      "vin_limit": -1,
      "includes": ["Unlimited VINs", "Audit-ready", "GUI", "All addons included"]
    },
    {
      "id": "oem",
      "name": "Tier 4 – OEM License",
      "price_usd": 17500,
      "vin_limit": -1,
      "includes": ["Resale rights", "Full source", "Custom GUI branding", "Audit + legal support"]
    }
  ]
}
EOF

# -------------------------- FILE: addons.json ---------------------------
ADDONS_FILE="$CONFIG_DIR/addons.json"
echo "[WRITE] Generating $ADDONS_FILE"
cat > "$ADDONS_FILE" << 'EOF'
{
  "_meta": "Optional per-license feature pricing.",
  "addons": [
    { "id": "vin_lock", "name": "VIN Lock Injector", "price_usd": 250 },
    { "id": "pdf_quote", "name": "PDF Quote Generator", "price_usd": 100 },
    { "id": "gpg_license", "name": "GPG License Signing", "price_usd": 75 },
    { "id": "nfc_serial", "name": "NFC/Serial Tag Binding", "price_usd": 150 },
    { "id": "qr_proof", "name": "Static QR Proof Embedding", "price_usd": 90 }
  ]
}
EOF

# ------------------------- FILE: quote_gen.py ---------------------------
QUOTE_GEN_PY="$SCRIPT_DIR/quote_gen.py"
echo "[WRITE] Generating $QUOTE_GEN_PY"
cat > "$QUOTE_GEN_PY" << 'EOF'
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
EOF

chmod +x "$QUOTE_GEN_PY"

# --------------------- FILE: test_quote_gen.py --------------------------
TEST_FILE="$TESTS_DIR/test_quote_gen.py"
echo "[WRITE] Generating $TEST_FILE"
cat > "$TEST_FILE" << 'EOF'
# tests/test_quote_gen.py

from scripts.quote_gen import generate_quote

def test_quote_total_and_hash():
    quote = generate_quote("installer", ["vin_lock", "pdf_quote"])
    total = quote["tier"]["price_usd"] + sum(a["price_usd"] for a in quote["addons"])
    assert quote["total_usd"] == total
    assert len(quote["sha256"]) == 64

def test_invalid_tier_raises():
    try:
        generate_quote("invalid_tier", [])
        assert False
    except ValueError:
        pass

def test_invalid_addon_raises():
    try:
        generate_quote("starter", ["unknown_addon"])
        assert False
    except ValueError:
        pass
EOF

# ------------------------- FINAL OUTPUT SUMMARY -------------------------
echo "======================================================================"
echo "[DONE] Pricing module successfully bootstrapped:"
echo " - $TIERS_FILE"
echo " - $ADDONS_FILE"
echo " - $QUOTE_GEN_PY"
echo " - $TEST_FILE"
echo " - output/quotes/ (write target)"
echo "======================================================================"
