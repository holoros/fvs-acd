#!/usr/bin/env bash
# =====================================================================
# run_bench_frozen.sh  --  CANONICAL FVS-ACD FREEZE HARNESS
#
# This is the canonical freeze wrapper for bench_parity.R. It exports the
# full frozen August operational environment and then invokes bench_parity.R
# for a given MODEL_FILE and CONFIG_TAG. Use this (or bench_frozen.sbatch,
# which calls it) whenever you need a scorecard that reproduces the frozen
# August operational baseline cb_v12101_results.csv.
#
# WHY THIS EXISTS:
#   A bare `Rscript bench_parity.R` leaves NB_AFAC/QC_AFAC at their INFLATING
#   DEFAULT of 1.0. That over-predicts dominant height and inflates NSVB volume
#   for every model and does NOT reproduce the frozen cb_v12101 baseline. Two
#   rounds of stale-number corrections traced back to bare afac=1 runs. Always
#   reproduce the freeze through this wrapper.
#
# FROZEN CANON (verified to reproduce cb_v12101_results.csv to the sixth
# decimal: per-stand max abs diff 0 on all nine metrics):
#   NB_AFAC=0.579 QC_AFAC=0.111 INDOMAIN=1
#   ONSET=0.30 BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
#   USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62
#   esi.anchor.coef NB c(0.885,0.01027) QC c(0.441,0.03783), ingrowth min DBH 5.0,
#   management gate OFF  --  these three are baked into the operational ops block
#   inside bench_parity.R itself, not set from the environment.
#
# USAGE:
#   ./run_bench_frozen.sh <MODEL_FILE> <CONFIG_TAG>
#   e.g. ./run_bench_frozen.sh ~/_scripts/AcadianGY_12.10.1.r cb_v12101_check
#   or via env:  MODEL_FILE=... CONFIG_TAG=... ./run_bench_frozen.sh
#
# OUTPUT: <CONFIG_TAG>_results.csv written in VERIFY_DIR (default ~/magplot/verify).
# No em dashes.
# =====================================================================
set -euo pipefail

VERIFY_DIR="${VERIFY_DIR:-$HOME/magplot/verify}"

MODEL_FILE="${1:-${MODEL_FILE:-}}"
CONFIG_TAG="${2:-${CONFIG_TAG:-}}"
if [ -z "$MODEL_FILE" ] || [ -z "$CONFIG_TAG" ]; then
  echo "usage: $0 <MODEL_FILE> <CONFIG_TAG>   (or set MODEL_FILE / CONFIG_TAG env)" >&2
  exit 2
fi
export MODEL_FILE CONFIG_TAG

# --- FROZEN CANON (do NOT edit; verified against cb_v12101_results.csv) ---
export NB_AFAC=0.579 QC_AFAC=0.111 INDOMAIN=1
export ONSET=0.30 BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62
# esi.anchor.coef, ingrowth.min.dbh=5.0 and the OFF management gate are set inside
# bench_parity.R's operational ops block, not here.

# Load the toolchain unless the caller already did (e.g. from the sbatch wrapper).
if [ -z "${FROZEN_MODULES_LOADED:-}" ]; then
  source /etc/profile.d/lmod.sh
  module load gcc/12.3.0 R/4.4.0
fi

cd "$VERIFY_DIR"
echo "[frozen] MODEL_FILE=$MODEL_FILE CONFIG_TAG=$CONFIG_TAG NB_AFAC=$NB_AFAC QC_AFAC=$QC_AFAC INDOMAIN=$INDOMAIN"
Rscript bench_parity.R
echo "[frozen] wrote ${VERIFY_DIR}/${CONFIG_TAG}_results.csv"
