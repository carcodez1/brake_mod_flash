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
        t.write(json.dumps(log_entry) + "\n")

    print(f"[✓] Delivery package created: {out_path}")

if __name__ == "__main__":
    make_zip(sys.argv[1], sys.argv[2])
