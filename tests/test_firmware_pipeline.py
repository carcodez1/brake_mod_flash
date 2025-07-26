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
