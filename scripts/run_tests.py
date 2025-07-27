#!/usr/bin/env python3
# File: scripts/run_tests.py
# Purpose: Hardened test runner for Brake Flasher Toolkit
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 2.0.0

import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime

# ─────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────
ROOT = Path(__file__).resolve().parent.parent
VENV = ROOT / ".venv"
TEST_DIR = ROOT / "tests"
COVERAGE_HTML = ROOT / "coverage_html"
COVERAGE_JSON = ROOT / "coverage_json"
LOGS_DIR = ROOT / "logs"
COVERAGE_THRESHOLD = 90  # percent

TIMESTAMP = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
LOG_FILE = LOGS_DIR / f"test_session_{TIMESTAMP}.log"

# ─────────────────────────────────────────────────────────────
# UTILITIES
# ─────────────────────────────────────────────────────────────

def fail(msg: str):
    print(f"[ERROR] {msg}", file=sys.stderr)
    sys.exit(1)

def ensure_paths():
    for path in [COVERAGE_HTML, COVERAGE_JSON, LOGS_DIR]:
        path.mkdir(parents=True, exist_ok=True)

def resolve_python_bin() -> Path:
    python_bin = VENV / "bin" / "python"
    if not python_bin.exists():
        fail(f"Python binary not found in .venv: {python_bin}")
    return python_bin

def verify_pytest_installed(python_bin: Path):
    try:
        subprocess.run(
            [python_bin, "-m", "pytest", "--version"],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
    except subprocess.CalledProcessError:
        fail("pytest is not installed in the virtual environment.")

def run_tests(python_bin: Path):
    cmd = [
        str(python_bin),
        "-m", "pytest",
        str(TEST_DIR),
        "--cov=.",
        "--cov-report=term-missing",
        f"--cov-report=html:{COVERAGE_HTML}",
        f"--cov-report=json:{COVERAGE_JSON}/coverage.json",
        "--tb=short"
    ]

    print("────────────────────────────────────────────────────────────")
    print("RUNNING FULL TEST SUITE")
    print(f"Test Directory : {TEST_DIR}")
    print(f"Python         : {python_bin}")
    print(f"Log File       : {LOG_FILE}")
    print("────────────────────────────────────────────────────────────")

    with open(LOG_FILE, "w") as log:
        result = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT)

    if result.returncode != 0:
        print("[FAIL] Tests failed. See log for details.")
        sys.exit(result.returncode)
    else:
        print("[OK] All tests passed.")

def enforce_coverage_threshold():
    coverage_file = COVERAGE_JSON / "coverage.json"
    if not coverage_file.exists():
        fail("coverage.json not found – test may not have run or failed silently.")

    import json
    with open(coverage_file, "r") as f:
        data = json.load(f)

    total = data.get("totals", {})
    coverage = total.get("percent_covered", 0)

    print(f"Coverage       : {coverage:.2f}% (threshold = {COVERAGE_THRESHOLD}%)")

    if coverage < COVERAGE_THRESHOLD:
        fail(f"Coverage below required threshold ({coverage:.2f}%)")
    else:
        print("[OK] Coverage threshold met.")

# ─────────────────────────────────────────────────────────────
# MAIN EXECUTION
# ─────────────────────────────────────────────────────────────
def main():
    ensure_paths()
    python_bin = resolve_python_bin()
    verify_pytest_installed(python_bin)
    run_tests(python_bin)
    enforce_coverage_threshold()

if __name__ == "__main__":
    main()
