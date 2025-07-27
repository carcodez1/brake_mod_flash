#!/usr/bin/env bash
# File: scripts/fix_all_script_permissions.sh
# Purpose: Make all scripts executable, fix line endings, and set correct permissions
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.0.0

set -euo pipefail
IFS=$'\n\t'

echo "──────────────────────────────────────────────────────"
echo "🔧 Fixing permissions for all scripts in repo..."
echo "�� Working directory: $(pwd)"
echo "──────────────────────────────────────────────────────"

# Ensure tools exist
for cmd in find chmod dos2unix file; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "[✗] Required tool not found: $cmd"
    exit 1
  fi
done

# Step 1: Make all `.sh` and `.py` scripts executable
echo "[*] Setting executable permissions on .sh and .py files..."
find . -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;

# Step 2: Normalize line endings (remove Windows CRLF)
echo "[*] Converting all scripts to Unix line endings (LF only)..."
find . -type f \( -name "*.sh" -o -name "*.py" \) -exec dos2unix {} \;

# Step 3: Remove BOM and warn on files with bad shebangs
echo "[*] Checking shebangs and file headers..."
while IFS= read -r -d '' file; do
  head -c 3 "$file" | grep -q $'\xef\xbb\xbf' && {
    echo "[✗] BOM detected in: $file — removing..."
    tail -c +4 "$file" > tmp && mv tmp "$file"
  }

  head -n1 "$file" | grep -q '^#!' || {
    echo "[!] Warning: No shebang found in $file"
  }

done < <(find . -type f \( -name "*.sh" -o -name "*.py" \) -print0)

# Step 4: Verify critical files exist and are accessible
REQUIRED_FILES=(
  "scripts/gen_all_vehicle_templates.sh"
  "scripts/render_config_to_ino.py"
  "firmware/templates/BrakeFlasher.j2"
)

echo "[*] Verifying required file accessibility..."
for f in "${REQUIRED_FILES[@]}"; do
  if [[ -f "$f" && -r "$f" ]]; then
    echo "[✓] OK: $f"
  else
    echo "[✗] ERROR: Missing or unreadable → $f"
  fi
done

echo "──────────────────────────────────────────────────────"
echo "✅ Script permissions, line endings, and headers fixed."

