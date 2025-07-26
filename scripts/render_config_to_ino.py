#!/usr/bin/env python3
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
