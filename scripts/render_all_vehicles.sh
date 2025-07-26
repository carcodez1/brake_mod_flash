#!/usr/bin/env bash
set -euo pipefail

vehicles=(
  hyundai_sonata_2020
  kia_optima_2019
  nissan_altima_2021
  hyundai_elantra_2018
  kia_sorento_2022
  genesis_g80_2023
)

for VEH in "${vehicles[@]}"; do
  echo "[*] Rendering: $VEH"
  make vehicle VEHICLE=$VEH BOARD=nano CUSTOMER=cust_$VEH
done
