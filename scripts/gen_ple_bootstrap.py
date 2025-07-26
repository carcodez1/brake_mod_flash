#!/usr/bin/env python3
import os
from pathlib import Path

BOOTSTRAP_PATH = Path("scripts/bootstrap_ple_system.sh")
os.makedirs("scripts", exist_ok=True)

BOOTSTRAP_SCRIPT = """#!/usr/bin/env bash
set -euo pipefail

echo "────────────────────────────────────────────"
echo "🚀 Bootstrapping BrakeFlasher PLE System"
echo "────────────────────────────────────────────"

RENDER_SCRIPT="scripts/render_config_to_ino.py"
DELIVERY_SCRIPT="scripts/delivery.py"
MAKEFILE="Makefile"
VEHICLE="hyundai_sonata_2020.json"
CUSTOMER="cust_jeff123"
TEMPLATE="templates/BrakeFlasher.ino.j2"
VEHICLE_NAME="${VEHICLE%.json}"
BINARY="firmware/binaries/${VEHICLE_NAME}.ino"
META="firmware/metadata/per_customer/${CUSTOMER}/firmware_version.json"
ZIP="delivery/${CUSTOMER}_${VEHICLE_NAME//_}.zip"
DELIVERY_LOG="firmware/metadata/per_customer/${CUSTOMER}/delivery_log.json"
TRACE_LOG="logs/delivery_trace.log"

[[ ! -f "$RENDER_SCRIPT" ]] && echo "[✗] Missing $RENDER_SCRIPT" && exit 1
[[ ! -f "$MAKEFILE" ]] && echo "[✗] Missing Makefile" && exit 1

echo "[*] Verifying jinja2 is installed..."
python3 -c "import jinja2" 2>/dev/null || { echo "[✗] Missing jinja2. Run: pip install jinja2"; exit 1; }

mkdir -p config/vehicles templates firmware/binaries \\
  firmware/metadata/per_customer/$CUSTOMER delivery tests logs

echo "[*] Creating sample vehicle config: $VEHICLE"
cat > config/vehicles/$VEHICLE <<EOF
{
  "vehicle": "Hyundai Sonata",
  "year": 2020,
  "pattern": [
    {"count": 3, "on": 100, "off": 100},
    {"count": 2, "on": 200, "off": 100},
    {"count": 1, "on": 500, "off": 0}
  ]
}
EOF

echo "[*] Creating Jinja2 firmware template..."
cat > $TEMPLATE <<'EOF'
// Auto-generated from Jinja2 template
// Vehicle: {{ vehicle }}
// Year: {{ year }}
const int inputPin = 3;
const int outputPin = 4;

void setup() {
  pinMode(inputPin, INPUT);
  pinMode(outputPin, OUTPUT);
}

void loop() {
  if (digitalRead(inputPin) == HIGH) {
    {% for step in pattern %}
    for (int i = 0; i < {{ step.count }}; i++) {
      digitalWrite(outputPin, HIGH);
      delay({{ step.on }});
      digitalWrite(outputPin, LOW);
      delay({{ step.off }});
    }
    {% endfor %}
  }
}
EOF

echo "[*] Patching $RENDER_SCRIPT..."
grep -q "argparse" "$RENDER_SCRIPT" || cat >> "$RENDER_SCRIPT" <<'EOF'

import argparse
import json
from pathlib import Path
from hashlib import sha256
from jinja2 import Template

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--template", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--meta", required=True)
    parser.add_argument("--board", default="nano")
    parser.add_argument("--customer_id", required=True)
    args = parser.parse_args()

    with open(args.input, "r", encoding="utf-8") as f:
        config = json.load(f)
    with open(args.template, "r", encoding="utf-8") as f:
        template = Template(f.read())
    rendered = template.render(**config)

    Path(args.output).write_text(rendered, encoding="utf-8")
    digest = sha256(rendered.encode("utf-8")).hexdigest()

    meta = {
        "vehicle": config.get("vehicle", "unknown"),
        "year": config.get("year", 0),
        "sha256": digest,
        "customer_id": args.customer_id
    }
    Path(args.meta).write_text(json.dumps(meta, indent=2), encoding="utf-8")

if __name__ == "__main__":
    main()
EOF

echo "[*] Patching Makefile..."
grep -q "^vehicle:" "$MAKEFILE" || cat >> "$MAKEFILE" <<'EOF'

vehicle:
	$(PY) scripts/render_config_to_ino.py \\
		--input config/vehicles/$(VEHICLE) \\
		--template templates/BrakeFlasher.ino.j2 \\
		--output firmware/binaries/$(VEHICLE:.json=.ino) \\
		--meta firmware/metadata/per_customer/$(CUSTOMER)/firmware_version.json \\
		--board $(BOARD) \\
		--customer_id $(CUSTOMER)
EOF

echo "[*] Creating delivery.py..."
cat > $DELIVERY_SCRIPT <<'EOF'
import zipfile, os, sys, json
from pathlib import Path
from datetime import datetime

def make_zip(customer_id, vehicle_file):
    base = vehicle_file.replace(".json", "")
    bin_path = f"firmware/binaries/{base}.ino"
    meta_path = f"firmware/metadata/per_customer/{customer_id}/firmware_version.json"
    out_path = f"delivery/{customer_id}_{base.replace('_','').title()}.zip"
    log_path = f"firmware/metadata/per_customer/{customer_id}/delivery_log.json"
    trace_log = "logs/delivery_trace.log"

    with zipfile.ZipFile(out_path, 'w') as z:
        z.write(bin_path, os.path.basename(bin_path))
        z.write(meta_path, os.path.basename(meta_path))

    now = datetime.utcnow().isoformat() + "Z"
    log_entry = {
        "timestamp": now,
        "customer_id": customer_id,
        "vehicle": base,
        "output_zip": out_path,
        "files": [bin_path, meta_path]
    }
    # Update customer delivery log
    existing = []
    if Path(log_path).exists():
        existing = json.loads(Path(log_path).read_text(encoding="utf-8"))
    existing.append(log_entry)
    Path(log_path).write_text(json.dumps(existing, indent=2), encoding="utf-8")

    # Append to global trace log
    with open(trace_log, "a", encoding="utf-8") as t:
        t.write(json.dumps(log_entry) + "\\n")

    print(f"[✓] Delivery package created: {out_path}")

if __name__ == "__main__":
    make_zip(sys.argv[1], sys.argv[2])
EOF

echo "[*] Creating test suite..."
cat > tests/test_render_config_to_ino_ple.py <<EOF
import json
from pathlib import Path
from hashlib import sha256

def test_firmware_exists():
    assert Path("$BINARY").exists()

def test_metadata_valid():
    path = Path("$META")
    assert path.exists()
    data = json.loads(path.read_text())
    assert "sha256" in data and len(data["sha256"]) == 64

def test_sha256_matches():
    path = Path("$BINARY")
    meta = json.loads(Path("$META").read_text())
    digest = sha256(path.read_text(encoding="utf-8").encode("utf-8")).hexdigest()
    assert digest == meta["sha256"]
EOF

echo "[*] Running Makefile target to render firmware..."
make vehicle BOARD=nano VEHICLE=$VEHICLE CUSTOMER=$CUSTOMER

echo "[*] Creating ZIP..."
python3 $DELIVERY_SCRIPT $CUSTOMER $VEHICLE

echo "[*] Running tests..."
pytest -v tests/test_render_config_to_ino_ple.py

echo "────────────────────────────────────────────"
echo "✅ PLE Boot Complete: $ZIP"
echo "────────────────────────────────────────────"
"""

# Write and set executable
BOOTSTRAP_PATH.write_text(BOOTSTRAP_SCRIPT, encoding="utf-8")
BOOTSTRAP_PATH.chmod(0o755)
print(f"[✓] Codegen complete: {BOOTSTRAP_PATH}")

