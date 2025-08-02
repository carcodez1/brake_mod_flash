# File: tests/test_pattern_validator.py
# Tests JSON Schema validation logic for brake flasher pattern configs
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.0.0

import json
import os
import pytest
import jsonschema

SCHEMA_PATH = "config/schema/flash_pattern.schema.json"

VALID_CONFIG = {
    "pattern": [
        {"count": 3, "on": 100, "off": 100},
        {"count": 2, "on": 200, "off": 150}
    ]
}

INVALID_CONFIG_MISSING_FIELD = {
    "pattern": [
        {"count": 3, "on": 100}  # missing 'off'
    ]
}

INVALID_CONFIG_WRONG_TYPE = {
    "pattern": [
        {"count": "3", "on": 100, "off": 100}  # count as string
    ]
}

@pytest.fixture(scope="module")
def schema():
    assert os.path.exists(SCHEMA_PATH), f"Schema missing: {SCHEMA_PATH}"
    with open(SCHEMA_PATH) as f:
        return json.load(f)

def test_valid_config_passes(schema):
    """Ensure valid flash pattern passes schema validation."""
    jsonschema.validate(instance=VALID_CONFIG, schema=schema)

def test_missing_field_fails(schema):
    """Ensure missing 'off' field fails validation."""
    with pytest.raises(jsonschema.exceptions.ValidationError):
        jsonschema.validate(instance=INVALID_CONFIG_MISSING_FIELD, schema=schema)

def test_wrong_type_fails(schema):
    """Ensure 'count' as string fails validation."""
    with pytest.raises(jsonschema.exceptions.ValidationError):
        jsonschema.validate(instance=INVALID_CONFIG_WRONG_TYPE, schema=schema)
