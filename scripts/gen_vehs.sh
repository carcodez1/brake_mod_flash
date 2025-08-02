#!/usr/bin/env bash
# File: scripts/gen_default_vehicle_configs.sh
# Purpose: Generate base vehicle config JSON files (Hyundai, Kia, Genesis)
# Author: Jeffrey Plewak
# License: Proprietary – NDA/IP Assignment
# Version: 1.1.0

set -euo pipefail

# ──────────────────────────────────────────────
# Directories
# ──────────────────────────────────────────────
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$ROOT_DIR/config/vehicles"

mkdir -p "$CONFIG_DIR"

# ──────────────────────────────────────────────
# Function: Write config file
# ──────────────────────────────────────────────
write_config() {
  local vehicle_id="$1"
  local config_file="$CONFIG_DIR/${vehicle_id}.json"

  cat > "$config_file" <<EOF
{
  "vehicle": "${vehicle_id}",
  "pattern": [
    {"count": 3, "on": 100, "off": 100},
    {"count": 2, "on": 200, "off": 200},
    {"count": 1, "on": 400, "off": 400}
  ],
  "metadata": {
    "version": "1.0.0",
    "jurisdiction": "NCGS",
    "generated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  }
}
EOF

  echo "[✓] Created config: $config_file"
}

# ──────────────────────────────────────────────
# Vehicle Definitions
# ──────────────────────────────────────────────

vehicles=(
  # Hyundai Sonata
  "hyundai_sonata_2018"
  "hyundai_sonata_2019"
  "hyundai_sonata_2020"
  "hyundai_sonata_2021"
  "hyundai_sonata_2022"
  "hyundai_sonata_2023"

  # Hyundai Elantra
  "hyundai_elantra_2017"
  "hyundai_elantra_2018"
  "hyundai_elantra_2019"
  "hyundai_elantra_2020"
  "hyundai_elantra_2021"

  # Hyundai Tucson
  "hyundai_tucson_2020"
  "hyundai_tucson_2021"
  "hyundai_tucson_2022"

  # Hyundai Ioniq
  "hyundai_ioniq_2022"
  "hyundai_ioniq_2023"

  # Kia Models
  "kia_optima_2018"
  "kia_optima_2019"
  "kia_optima_2020"
  "kia_k5_2021"
  "kia_sorento_2020"
  "kia_sorento_2021"
  "kia_sportage_2019"
  "kia_sportage_2020"
  "kia_niro_2022"
  "kia_niro_2023"

  # Genesis Full Coverage (2015–2023)
  "genesis_g70_2019"
  "genesis_g70_2020"
  "genesis_g70_2021"
  "genesis_g70_2022"
  "genesis_g70_2023"

  "genesis_g80_2015"
  "genesis_g80_2016"
  "genesis_g80_2017"
  "genesis_g80_2018"
  "genesis_g80_2019"
  "genesis_g80_2020"
  "genesis_g80_2021"
  "genesis_g80_2022"
  "genesis_g80_2023"

  "genesis_g90_2017"
  "genesis_g90_2018"
  "genesis_g90_2019"
  "genesis_g90_2020"
  "genesis_g90_2021"
  "genesis_g90_2022"
  "genesis_g90_2023"
)

# ──────────────────────────────────────────────
# Generate Configs
# ──────────────────────────────────────────────
echo "Generating default vehicle configs in: $CONFIG_DIR"
for vehicle in "${vehicles[@]}"; do
  write_config "$vehicle"
done

echo "[✓] All vehicle config files generated successfully."

