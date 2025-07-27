#!/usr/bin/env bash
# File: scripts/fix_config_structure.sh
# Description: Fix JSON config files that are raw arrays instead of objects with 'pattern' key
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assignment
# Version: 1.2.0
# Date: 2025-07-26

set -euo pipefail

# ─────────────────────────────────────────────────────────────
# USAGE:
#   ./fix_config_structure.sh                    # defaults to gui/config_template.json
#   ./fix_config_structure.sh path/to/file.json  # single file
#   ./fix_config_structure.sh --batch dir/       # batch fix all .json in dir
# ─────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────
DEFAULT_FILE="gui/config_template.json"
BACKUP_DIR=".backups"
TIMESTAMP="$(date +%Y%m%dT%H%M%S)"
mkdir -p "$BACKUP_DIR"

# ─────────────────────────────────────────────────────────────
# LOGGING FUNCTIONS
# ─────────────────────────────────────────────────────────────
log()   { printf "[%s] %s\n" "$1" "$2"; }
ok()    { log "✓" "$1"; }
fail()  { log "✗" "$1" >&2; }
warn()  { log "!" "$1"; }

# ─────────────────────────────────────────────────────────────
# DEPENDENCY CHECK
# ─────────────────────────────────────────────────────────────
if ! command -v jq >/dev/null 2>&1; then
  fail "Missing 'jq'. Please install it (e.g., sudo apt install jq)"
  exit 127
fi

# ─────────────────────────────────────────────────────────────
# FUNCTION: FIX A SINGLE FILE
# ─────────────────────────────────────────────────────────────
fix_file() {
  local file="$1"
  local fname="$(basename "$file")"
  local backup_file="$BACKUP_DIR/${fname}.backup.${TIMESTAMP}"
  local temp_file="${file}.tmp"

  if [ ! -f "$file" ]; then
    fail "Not found: $file"
    return 1
  fi

  local type
  type=$(jq -r 'type' "$file" 2>/dev/null || echo "invalid")

  if [[ "$type" == "array" ]]; then
    warn "Fixing array → object with 'pattern' key: $file"
    cp "$file" "$backup_file"
    jq '{pattern: .}' "$file" > "$temp_file" && mv "$temp_file" "$file"
    ok "Patched: $file"
    ok "Backup: $backup_file"
    return 0

  elif [[ "$type" == "object" ]]; then
    if jq 'has("pattern")' "$file" | grep -q true; then
      ok "Already valid: $file"
      return 0
    else
      warn "Object but no 'pattern' key: $file – skipped"
      return 2
    fi

  else
    fail "Invalid JSON or unexpected format: $file"
    return 3
  fi
}

# ─────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────
main() {
  if [[ $# -eq 0 ]]; then
    fix_file "$DEFAULT_FILE"
  elif [[ "$1" == "--batch" ]]; then
    local dir="${2:-config/vehicles}"
    if [ ! -d "$dir" ]; then
      fail "Batch mode failed – directory does not exist: $dir"
      exit 1
    fi

    warn "Batch mode: scanning $dir/*.json"
    local count=0
    local fixed=0
    for f in "$dir"/*.json; do
      if [ -f "$f" ]; then
        ((count++))
        if fix_file "$f"; then
          ((fixed++))
        fi
      fi
    done
    echo ""
    ok "Batch complete – Files scanned: $count | Fixed: $fixed"
  else
    fix_file "$1"
  fi
}

main "$@"
