import json
import zipfile
from hashlib import sha256
from pathlib import Path
from datetime import datetime, timezone
import pytest

VEHICLE_NAME = "hyundai_sonata_2020"
CUSTOMER_ID = "cust_jeff123"
BINARY = Path(f"firmware/binaries/{VEHICLE_NAME}.ino")
META = Path(f"firmware/metadata/per_customer/{CUSTOMER_ID}/firmware_version.json")
ZIP = Path(f"delivery/{CUSTOMER_ID}_{VEHICLE_NAME.replace('_','').title()}.zip")
LOG = Path(f"firmware/metadata/per_customer/{CUSTOMER_ID}/delivery_log.json")

REQUIRED_META_KEYS = {
    "sha256": str,
    "vehicle": str,
    "year": int,
    "customer_id": str
}

def test_ino_file_exists_and_utf8_clean():
    assert BINARY.exists(), f"[✗] Firmware .ino file missing: {BINARY}"
    try:
        content = BINARY.read_text(encoding="utf-8")
        assert content.endswith("}") or content.endswith("}\n"), "[✗] .ino file missing proper closing brace or newline"
    except UnicodeDecodeError:
        pytest.fail(f"[✗] {BINARY} is not UTF-8 decodable")


def test_metadata_file_valid_schema():
    assert META.exists(), f"[✗] Metadata file missing: {META}"
    try:
        meta = json.loads(META.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        pytest.fail(f"[✗] Metadata file corrupted: {e}")

    for key, expected_type in REQUIRED_META_KEYS.items():
        assert key in meta, f"[✗] Missing metadata key: {key}"
        assert isinstance(meta[key], expected_type), f"[✗] Metadata key {key} has wrong type: expected {expected_type}, got {type(meta[key])}"


def test_sha256_hash_matches_file():
    firmware = BINARY.read_text(encoding="utf-8")
    actual_hash = sha256(firmware.encode("utf-8")).hexdigest()
    expected_hash = json.loads(META.read_text(encoding="utf-8"))["sha256"]
    assert actual_hash == expected_hash, f"[✗] SHA256 mismatch\nExpected: {expected_hash}\nActual:   {actual_hash}"


def test_flash_pattern_logic_present():
    code = BINARY.read_text(encoding="utf-8")
    fragments = [
        "for (int i = 0; i < 3",
        "delay(100);",
        "delay(200);",
        "delay(500);"
    ]
    for frag in fragments:
        assert frag in code, f"[✗] Expected flash pattern fragment not found: {frag}"


def test_delivery_zip_contents_and_integrity():
    assert ZIP.exists(), f"[✗] Delivery ZIP not found: {ZIP}"
    try:
        with zipfile.ZipFile(ZIP, "r") as z:
            assert z.testzip() is None, f"[✗] ZIP integrity test failed"
            files = z.namelist()
            assert "hyundai_sonata_2020.ino" in files
            assert "firmware_version.json" in files
            assert len(files) == len(set(files)), f"[✗] Duplicate filenames found in ZIP: {files}"
    except zipfile.BadZipFile:
        pytest.fail(f"[✗] ZIP archive is corrupted: {ZIP}")


def test_delivery_log_structure_and_content():
    assert LOG.exists(), f"[✗] Delivery log missing: {LOG}"
    try:
        entries = json.loads(LOG.read_text(encoding="utf-8"))
        assert isinstance(entries, list), "[✗] Log file is not a list"
    except json.JSONDecodeError:
        pytest.fail("[✗] Delivery log is not valid JSON")

    matching = [e for e in entries if e.get("vehicle") == VEHICLE_NAME]
    assert matching, f"[✗] No delivery log entry for vehicle: {VEHICLE_NAME}"

    for entry in matching:
        assert "timestamp" in entry
        try:
            dt = datetime.fromisoformat(entry["timestamp"].replace("Z", "+00:00"))
            assert dt <= datetime.now(timezone.utc), "[✗] Future timestamp in log entry"
        except ValueError:
            pytest.fail(f"[✗] Invalid timestamp format in delivery log: {entry['timestamp']}")


def test_negative_metadata_missing_key(monkeypatch):
    bad_meta_path = META.parent / "bad_meta.json"
    bad_meta_path.write_text(json.dumps({"vehicle": "test"}), encoding="utf-8")

    with pytest.raises(AssertionError):
        meta = json.loads(bad_meta_path.read_text(encoding="utf-8"))
        for key in REQUIRED_META_KEYS:
            assert key in meta
