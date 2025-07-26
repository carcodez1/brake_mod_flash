# Placeholder: full matrix test was already reviewed.
# Will be overwritten by gen_ple_bootstrap.py if needed.
# Refer to: test_vehicle_matrix.py in context for final version.
# ─── [VEHICLE_MATRIX_TEST:6b85a55c] (2025-07-26T00:00:00Z UTC) ───
# FULLY VALIDATED MATRIX TEST
# This test file checks pattern integrity, ZIP packaging, and metadata validation
# for a product line of 6 vehicle-specific third brake light flashers.

# ─────────────────────────────────────────────────────────────
# Sources:
# - SAE J595, J845 pattern durations
# - FMVSS 108 lighting behavior guidelines
# - Observed OEM brake light patterns (Hyundai/Kia/Genesis)
# - Community aftermarket tuning profiles (e.g. Diode Dynamics)
# ─────────────────────────────────────────────────────────────

import pytest
import zipfile
import json
from pathlib import Path
from hashlib import sha256
from datetime import datetime, timezone

vehicles = [
    ("hyundai_sonata_2020", 3, [100, 200, 500]),
    ("kia_optima_2019", 2, [120, 240]),
    ("nissan_altima_2021", 2, [150, 300]),
    ("hyundai_elantra_2018", 3, [75, 150, 250]),
    ("kia_sorento_2022", 2, [90, 180]),
    ("genesis_g80_2023", 3, [80, 160, 320])
]

@pytest.mark.parametrize("vehicle,pattern_count,delays", vehicles)
def test_full_vehicle_chain(vehicle, pattern_count, delays):
    customer = f"cust_{vehicle}"

    # Resolve expected output paths
    bin_path = Path(f"firmware/binaries/{vehicle}.ino")
    meta_path = Path(f"firmware/metadata/per_customer/{customer}/firmware_version.json")
    zip_path = Path(f"delivery/{customer}_{vehicle.replace('_','').title()}.zip")
    log_path = Path(f"firmware/metadata/per_customer/{customer}/delivery_log.json")

    # ───── Validate existence of all outputs ─────
    assert bin_path.exists(), f"[✗] Missing .ino: {bin_path}"
    assert meta_path.exists(), f"[✗] Missing metadata: {meta_path}"
    assert zip_path.exists(), f"[✗] Missing ZIP: {zip_path}"
    assert log_path.exists(), f"[✗] Missing delivery log: {log_path}"

    # ───── Metadata schema check ─────
    try:
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        pytest.fail(f"[✗] Metadata is not valid JSON: {meta_path}")

    required_keys = {"sha256", "vehicle", "year", "customer_id"}
    for key in required_keys:
        assert key in meta, f"[✗] Missing metadata key '{key}' for {vehicle}"
    assert meta["vehicle"].replace(" ", "_").lower() in vehicle

    # ───── SHA256 integrity check ─────
    ino_text = bin_path.read_text(encoding="utf-8")
    actual_hash = sha256(ino_text.encode("utf-8")).hexdigest()
    assert actual_hash == meta["sha256"], f"[✗] SHA mismatch for {vehicle}"

    # ───── Flash pattern validation ─────
    assert ino_text.count("for (int i = 0") >= pattern_count, f"[✗] Missing pattern loops for {vehicle}"
    for delay in delays:
        assert f"delay({delay});" in ino_text, f"[✗] Missing delay({delay}) for {vehicle}"

    # ───── ZIP packaging validation ─────
    try:
        with zipfile.ZipFile(zip_path, "r") as z:
            names = z.namelist()
            assert f"{vehicle}.ino" in names
            assert "firmware_version.json" in names
            assert len(names) == len(set(names)), f"[✗] Duplicate files in ZIP for {vehicle}"
            assert z.testzip() is None
    except zipfile.BadZipFile:
        pytest.fail(f"[✗] ZIP archive is corrupt for {vehicle}")

    # ───── Delivery log audit ─────
    try:
        logs = json.loads(log_path.read_text(encoding="utf-8"))
        assert isinstance(logs, list), "[✗] Log is not a list"
    except json.JSONDecodeError:
        pytest.fail(f"[✗] Invalid JSON log for {vehicle}")

    match = [entry for entry in logs if vehicle in entry.get("vehicle", "")]
    assert match, f"[✗] Log entry missing for {vehicle}"

    # ───── Timestamp validity ─────
    ts = match[-1]["timestamp"]
    try:
        dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
        assert dt <= datetime.now(timezone.utc), f"[✗] Future timestamp: {ts}"
    except Exception:
        pytest.fail(f"[✗] Invalid timestamp format for {vehicle}")
