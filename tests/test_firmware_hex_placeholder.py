# ─── [HEX_PLACEHOLDER_TEST:f43a12e9] (2025-07-26T00:00:00Z UTC) ───
# Placeholder for compiled firmware (.hex) SHA256 integrity validation
# This test ensures future compiled firmware integrity checks are enforced.
# When implemented, the .hex files will be hashed and matched against manifest.

# ─────────────────────────────────────────────────────────────
# Future coverage:
# - Match each .hex file's SHA256 hash to `sha256_manifest.txt`
# - Enforce integrity before flashing
# - Support for secure delivery and customer traceability
# ─────────────────────────────────────────────────────────────

import pytest
from pathlib import Path

HEX_MANIFEST = Path("firmware/metadata/sha256_manifest.txt")

def test_hex_manifest_exists():
    assert HEX_MANIFEST.exists(), "[✗] SHA256 hex manifest is missing"

@pytest.mark.skip(reason="Pending .hex compilation and hashing support")
def test_hex_file_hashes_match_manifest():
    assert False, "Hex validation not implemented – replace with hash check later"
