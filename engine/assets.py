"""Module: assets - Generates test configuration JSONs"""

from pathlib import Path

def generate_assets():
    print("[•] Generating test assets...")
    test_dir = Path("config/test")
    test_dir.mkdir(parents=True, exist_ok=True)

    # Example test file
    (test_dir / "test_vehicle.json").write_text('{"test": true}')
