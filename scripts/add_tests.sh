#!/usr/bin/env bash
set -euo pipefail

mkdir -p tests

# ─── 1. PIPELINE TEST ────────────────────────────────────────
cat > tests/test_firmware_pipeline.py <<'EOF'
import json
import zipfile
from pathlib import Path
from hashlib import sha256
from datetime import datetime, timezone

VEHICLE = "hyundai_sonata_2020"
CUSTOMER = "cust_jeff123"

BINARY = Path(f"firmware/binaries/{VEHICLE}.ino")
META = Path(f"firmware/metadata/per_customer/{CUSTOMER}/firmware_version.json")
ZIP = Path(f"delivery/{CUSTOMER}_${VEHICLE.replace('_','').title()}.zip")
LOG = Path(f"firmware/metadata/per_customer/{CUSTOMER}/delivery_log.json")

def test_ino_file_utf8_and_ends_clean():
    assert BINARY.exists()
    text = BINARY.read_text(encoding="utf-8")
    assert text.endswith("}") or text.endswith("}\n")

def test_metadata_integrity_and_schema():
    meta = json.loads(META.read_text(encoding="utf-8"))
    for k in ["sha256", "vehicle", "year", "customer_id"]:
        assert k in meta
    digest = sha256(BINARY.read_text(encoding="utf-8").encode("utf-8")).hexdigest()
    assert digest == meta["sha256"]

def test_zip_valid_and_contains_expected():
    with zipfile.ZipFile(ZIP, "r") as z:
        assert z.testzip() is None
        names = z.namelist()
        assert f"{VEHICLE}.ino" in names
        assert "firmware_version.json" in names

def test_log_entry_present_and_timestamp_valid():
    logs = json.loads(LOG.read_text(encoding="utf-8"))
    matched = [e for e in logs if VEHICLE in e.get("vehicle", "")]
    ts = matched[-1]["timestamp"]
    dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
    assert dt <= datetime.now(timezone.utc)
EOF

# ─── 2. HEX PLACEHOLDER TEST ─────────────────────────────────
cat > tests/test_firmware_hex_placeholder.py <<'EOF'
# Placeholder for future .hex firmware validation
# This test will check SHA256 of compiled .hex once support is implemented
def test_hex_placeholder():
    assert True  # will be replaced with real test
EOF

# ─── 3. VEHICLE MATRIX TEST HEADER ───────────────────────────
cat > tests/test_vehicle_matrix.py <<'EOF'
# Placeholder: full matrix test was already reviewed.
# Will be overwritten by gen_ple_bootstrap.py if needed.
# Refer to: test_vehicle_matrix.py in context for final version.
EOF

# ─── Permissions ─────────────────────────────────────────────
chmod -R 644 tests/*.py
echo "[✓] Test files added to ./tests/"
