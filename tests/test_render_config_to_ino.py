import os
import subprocess
from pathlib import Path

def test_render_config_to_ino_cli(tmp_path):
    os.environ["VEHICLE"] = "test_car_model_2025"
    os.environ["CUSTOMER"] = "cust_test_car_model_2025"
    os.environ["CONFIG"] = "gui/config_template.json"

    out_ino = tmp_path / "firmware_test.ino"
    out_meta = tmp_path / "firmware_version.json"

    result = subprocess.run([
        "python3", "scripts/render_config_to_ino.py",
        "--output", str(out_ino),
        "--meta", str(out_meta)
    ], capture_output=True, text=True)

    assert result.returncode == 0, f"Render failed: {result.stderr}"
    assert out_ino.exists(), "Missing .ino output"
    assert out_meta.exists(), "Missing metadata output"

    content = out_meta.read_text()
    assert '"vehicle": "test_car_model_2025"' in content
