# File: scripts/run_tests.py
# Author: Jeffrey Plewak
# Description: Python-native test runner with coverage validation and diagnostics
# License: Proprietary – NDA / IP Assigned
# Version: 1.0.1
# Compatibility: Python 3.7+

import os
import sys
import subprocess
import venv
import json
from pathlib import Path

VENV_DIR = ".venv"
MODULE_PATH = "scripts/render_config_to_ino.py"
COV_MODULE = "scripts.render_config_to_ino"
COVERAGE_MIN = 80
HTML_DIR = "coverage_html"
JSON_DIR = "coverage_json"
COV_ARGS = [
    "-m", "pytest",
    "tests",
    f"--cov={COV_MODULE}",
    "--cov-branch",
    f"--cov-report=term-missing:skip-covered",
    f"--cov-report=html:{HTML_DIR}",
    "--cov-report=xml:coverage.xml",
    f"--cov-report=json:{JSON_DIR}/coverage.json"
]

def ensure_python():
    if not sys.version_info >= (3, 7):
        print("[✗] Python >= 3.7 is required", file=sys.stderr)
        sys.exit(1)
    print(f"[✓] Python version: {sys.version_info.major}.{sys.version_info.minor}")

def ensure_venv():
    if not os.path.isdir(VENV_DIR):
        print("[+] Creating virtual environment...")
        venv.create(VENV_DIR, with_pip=True)
    else:
        print("[✓] Virtual environment exists")

def venv_python():
    return os.path.join(VENV_DIR, "Scripts", "python.exe") if os.name == "nt" else os.path.join(VENV_DIR, "bin", "python")

def install_deps(python_exe):
    print("[+] Installing test dependencies...")
    subprocess.run([python_exe, "-m", "pip", "install", "--upgrade", "pip"], check=True)
    subprocess.run([python_exe, "-m", "pip", "install", "pytest", "pytest-cov", "mock", "coverage"], check=True)

def run_tests(python_exe):
    print("[+] Running tests with coverage...")
    os.makedirs(HTML_DIR, exist_ok=True)
    os.makedirs(JSON_DIR, exist_ok=True)
    result = subprocess.run([python_exe] + COV_ARGS)
    return result.returncode

def validate_coverage():
    coverage_path = Path(JSON_DIR) / "coverage.json"
    if not coverage_path.exists():
        print("[✗] coverage.json missing – test run did not complete or failed.")
        return 1

    with open(coverage_path, "r") as f:
        try:
            data = json.load(f)
            totals = data.get("totals")
            if not totals or "percent_covered" not in totals:
                print("[✗] Invalid or incomplete coverage.json – missing totals.")
                return 1
            pct = float(totals["percent_covered"])
        except Exception as e:
            print(f"[✗] Failed to parse coverage.json: {e}")
            return 1

    print(f"[i] Coverage: {pct:.2f}%")
    if pct < COVERAGE_MIN:
        print(f"[✗] Coverage below {COVERAGE_MIN}%. Failing build.")
        return 1

    print(f"[✓] Coverage OK ≥ {COVERAGE_MIN}%")
    return 0

def main():
    ensure_python()
    ensure_venv()
    py = venv_python()
    install_deps(py)

    if run_tests(py) != 0:
        print("[✗] Tests failed.")
        sys.exit(1)

    if validate_coverage() != 0:
        sys.exit(1)

    print("[✓] All tests passed.")
    print(f"    HTML Coverage: file://{os.path.abspath(HTML_DIR)}/index.html")

if __name__ == "__main__":
    main()
