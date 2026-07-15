#!/bin/bash
#SBATCH --job-name=comp_frozen
#SBATCH --account=puom0008
#SBATCH --time=00:45:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=comp_frozen_%j.out
# =====================================================================
# comp_frozen.sbatch -- species-composition-over-time harness on the FROZEN
# August operational environment. Runs bench_species_comp_frozen.R (a
# non-invasive copy of bench_parity.R that adds per-group basal-area fraction
# columns SWF/SFF/OSWF/HWF at t1, observed t2, predicted t2) for the three
# flagship models. Reproduces the frozen canon (NB_AFAC=0.579 QC_AFAC=0.111).
# Aggregates only. No em dashes.
# =====================================================================
set -e
source /etc/profile.d/lmod.sh
module purge
module load gcc/12.3.0 R/4.4.0

cd /users/PUOM0008/crsfaaron/magplot/verify

# --- FROZEN CANON (mirrors run_bench_frozen.sh; do NOT edit) ---
export NB_AFAC=0.579 QC_AFAC=0.111 INDOMAIN=1
export ONSET=0.30 BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62

run_one () {
  export MODEL_FILE="$1"
  export CONFIG_TAG="$2"
  echo "[comp] MODEL_FILE=$MODEL_FILE CONFIG_TAG=$CONFIG_TAG"
  Rscript bench_species_comp_frozen.R
  echo "[comp] wrote ${CONFIG_TAG}_results.csv"
}

run_one "$HOME/_scripts/AcadianGY_12.5.0.r"  comp_v125_frozen
run_one "$HOME/_scripts/AcadianGY_12.7.0.r"  comp_v1270_frozen
run_one "$HOME/_scripts/AcadianGY_12.10.1.r" comp_v12101_frozen

echo "=== comp_frozen ALL DONE ==="
