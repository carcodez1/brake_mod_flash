# tests/test_quote_gen.py

from scripts.quote_gen import generate_quote

def test_quote_total_and_hash():
    quote = generate_quote("installer", ["vin_lock", "pdf_quote"])
    total = quote["tier"]["price_usd"] + sum(a["price_usd"] for a in quote["addons"])
    assert quote["total_usd"] == total
    assert len(quote["sha256"]) == 64

def test_invalid_tier_raises():
    try:
        generate_quote("invalid_tier", [])
        assert False
    except ValueError:
        pass

def test_invalid_addon_raises():
    try:
        generate_quote("starter", ["unknown_addon"])
        assert False
    except ValueError:
        pass
