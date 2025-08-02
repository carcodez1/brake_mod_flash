#!/usr/bin/env bash
# File: scripts/gen_default_vehicle_configs.sh
# Purpose: Generate per-vehicle brake flasher JSON configs with pattern_mode + compliance_level + metadata
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.3.0

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$ROOT_DIR/config/vehicles"
mkdir -p "$CONFIG_DIR"

# Pattern presets
declare -A patterns=(
  ["default"]='[{"count":3,"on":100,"off":100},{"count":2,"on":200,"off":200},{"count":1,"on":400,"off":400}]'
  ["sport"]='[{"count":4,"on":80,"off":80},{"count":3,"on":160,"off":160},{"count":2,"on":240,"off":240}]'
  ["luxury"]='[{"count":2,"on":150,"off":150},{"count":2,"on":300,"off":300}]'
  ["compact"]='[{"count":3,"on":90,"off":90},{"count":2,"on":180,"off":180},{"count":1,"on":300,"off":300}]'
  ["aggressive"]='[{"count":6,"on":60,"off":60},{"count":4,"on":120,"off":120}]'
  ["strobe"]='[{"count":8,"on":40,"off":40},{"count":4,"on":80,"off":80}]'
  ["illegal"]='[{"count":10,"on":30,"off":30},{"count":6,"on":50,"off":50}]'
)

# Mode/compliance selector
select_profile_and_compliance() {
  local vehicle="$1"
  local mode="default"
  local compliance="legal"

  case "$vehicle" in
    *g80*|*g90*)        mode="luxury"; compliance="legal" ;;
    *elantra*|*niro*)   mode="compact"; compliance="legal" ;;
    *sportage*|*tucson*|*k5*) mode="sport"; compliance="legal" ;;
    *ioniq*2023|*g70*2023) mode="aggressive"; compliance="noncompliant" ;;
    *g70*2022|*optima*2020) mode="strobe"; compliance="experimental" ;;
    *sorento*2021|*sonata*2023) mode="illegal"; compliance="banned" ;;
    *) mode="default"; compliance="legal" ;;
  esac

  echo "$mode|$compliance"
}

# Generate config JSON
write_config() {
  local vehicle_id="$1"
  local file="$CONFIG_DIR/${vehicle_id}.json"

  IFS="|" read -r pattern_mode compliance_level <<< "$(select_profile_and_compliance "$vehicle_id")"
  local pattern="${patterns[$pattern_mode]}"

  cat > "$file" <<EOF
{
  "which": {
    "target_vehicle": ["$vehicle_id"]
  },
  "when": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "pattern_mode": "$pattern_mode",
  "pattern": $pattern,
  "metadata": {
    "version": "1.0.0",
    "jurisdiction": "NCGS",
    "compliance_level": "$compliance_level",
    "generator": "gen_default_vehicle_configs.sh"
  }
}
EOF

  echo "[✓] $vehicle_id → pattern_mode=$pattern_mode, compliance=$compliance_level"
}

# Vehicle matrix
vehicles=(
  "hyundai_sonata_2023"
  "hyundai_elantra_2021"
  "hyundai_tucson_2022"
  "hyundai_ioniq_2023"
  "kia_optima_2020"
  "kia_k5_2021"
  "kia_sorento_2021"
  "kia_niro_2023"
  "kia_sportage_2020"
  "genesis_g70_2023"
  "genesis_g80_2023"
  "genesis_g90_2023"
)

# Execute
echo "🔧 Generating configs to: $CONFIG_DIR"
for v in "${vehicles[@]}"; do
  write_config "$v"
done

echo "[✓] All configurations generated with 7DP-compliant metadata."
