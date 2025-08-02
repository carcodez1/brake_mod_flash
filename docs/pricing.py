#!/usr/bin/env python3

import argparse, datetime, json, uuid

TIERS = {
    "1": {"label": "Starter Kit", "price": 179, "vin_limit": 1, "source": False},
    "2": {"label": "Pro Installer", "price": 1490, "vin_limit": 25, "source": False},
    "3": {"label": "Fleet License", "price": 4900, "vin_limit": "∞ (internal use)", "source": False},
    "4": {"label": "OEM/Enterprise", "price": 17500, "vin_limit": "100+ (extendable)", "source": True}
}

ADDONS = {
    "nfc": {"label": "NFC Config Pairing", "price": 35, "per_unit": True},
    "vinlock": {"label": "VIN Locking Module", "price": 75, "per_unit": True},
    "pdf": {"label": "PDF/A-3 Audit Export", "price": 495, "per_unit": False},
    "branding": {"label": "White-Label GUI", "price": 1000, "per_unit": False},
    "sla": {"label": "Enterprise SLA (1 yr)", "price": 1200, "per_unit": False}
}


def generate_quote(args):
    uid = str(uuid.uuid4())[:8]
    date = datetime.datetime.now().strftime("%Y-%m-%d")
    tier = TIERS[args.tier]

    base = tier["price"]
    addons = []

    for item in args.addon or []:
        if ":" in item:
            key, count = item.split(":")
            count = int(count)
        else:
            key, count = item, 1

        if key not in ADDONS:
            raise Exception(f"Unknown addon: {key}")

        addon = ADDONS[key]
        total = addon["price"] * count if addon["per_unit"] else addon["price"]
        addons.append({
            "id": key,
            "label": addon["label"],
            "unit_price": addon["price"],
            "quantity": count,
            "total": total
        })
        base += total

    quote = {
        "quote_id": uid,
        "date": date,
        "customer": {
            "name": args.customer,
            "email": args.email
        },
        "tier": {
            "id": args.tier,
            "label": tier["label"],
            "vin_limit": tier["vin_limit"],
            "source_access": tier["source"],
            "base_price": TIERS[args.tier]["price"]
        },
        "addons": addons,
        "paid": float(args.paid or 0),
        "due": base - float(args.paid or 0),
        "total": base
    }

    if args.json:
        print(json.dumps(quote, indent=2))
    else:
        print(render_markdown(quote))


def render_markdown(quote):
    out = [f"# BrakeFlasher Toolkit Quote — {quote['quote_id']}",
           f"**Date:** {quote['date']}",
           f"**Customer:** {quote['customer']['name']}  \n**Email:** {quote['customer']['email']}\n",
           f"## License Tier: {quote['tier']['label']}",
           f"- VIN Limit: {quote['tier']['vin_limit']}",
           f"- Source Code Access: {'Yes' if quote['tier']['source_access'] else 'No'}",
           f"- Base Price: ${quote['tier']['base_price']}\n"]

    if quote['addons']:
        out.append("## Add-Ons:")
        for a in quote['addons']:
            q = f" x{a['quantity']}" if a['quantity'] > 1 else ""
            out.append(f"- {a['label']}{q}: ${a['total']}")

    out.append(f"\n**Total Price:** ${quote['total']}")
    out.append(f"**Amount Paid:** ${quote['paid']}")
    out.append(f"**Remaining Due:** ${quote['due']}")

    return "\n".join(out)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate BrakeFlasher quote")
    parser.add_argument("--customer", required=True, help="Customer name")
    parser.add_argument("--email", required=True, help="Customer email")
    parser.add_argument("--tier", required=True, choices=["1", "2", "3", "4"], help="License tier")
    parser.add_argument("--addon", action="append", help="Add-on ID (e.g. vinlock:2, pdf)")
    parser.add_argument("--paid", type=float, help="Amount already paid")
    parser.add_argument("--json", action="store_true", help="Output in JSON format")

    args = parser.parse_args()
    generate_quote(args)
