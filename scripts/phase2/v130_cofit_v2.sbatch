#!/usr/bin/env bash
#SBATCH --account=PUOM0008
#SBATCH --job-name=v130_cofit_v2
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/v130_cofit_v2_%j.out
# =====================================================================
# v130_cofit_v2.sbatch
# FVS-ACD v13.0 Phase 2, Test B: widen the QC ascale clamp and rerun the
# hardened co-fit so QC dominant height can be pulled off the old 1.35 ceiling.
#
# Sequence:
#   (1) patch_ascale_clamp.py rewrites the calc_dht ascale clamp so the band is
#       env driven, reading ASCALE_LO / ASCALE_HI. Input AcadianGY_13.0_v2.r,
#       output AcadianGY_13.0_wideclamp.r.
#   (2) point the co-fit at the wideclamp model with a widened band
#       (ASCALE_LO=0.80, ASCALE_HI=1.60) and run 4 damped Gauss-Seidel iters.
#   (3) run the hardened co-fit driver, which does its own final bench + gate
#       (COFIT_FINAL_GATE=1), so exactly one final verdict is captured.
#
# The driver and patcher are uploaded to Cardinal home ~/ by the main thread.
# The bench (~/bench_parity_v130_run.R) and gate (~/v130_score_gate_v2.R) already
# exist as home symlinks to the verify dir copies. No em dashes.
# =====================================================================
set -euo pipefail

# Module order matters on Cardinal.
source /etc/profile.d/lmod.sh
module load gcc/12.3.0 R/4.4.0

# ---------------------------------------------------------------------
# (1) Widen the ascale clamp: make the calc_dht band env driven.
# ---------------------------------------------------------------------
python3 ~/patch_ascale_clamp.py ~/AcadianGY_13.0_v2.r ~/AcadianGY_13.0_wideclamp.r

# ---------------------------------------------------------------------
# (2) Point the co-fit at the wideclamp model with the widened band and knobs.
# ---------------------------------------------------------------------
export MODEL_FILE=~/AcadianGY_13.0_wideclamp.r ASCALE_LO=0.80 ASCALE_HI=1.60 COFIT_ITERS=4 COFIT_GAIN=0.9 COFIT_START_FROM_CSV=0 COFIT_BUILD=0 COFIT_FINAL_GATE=1

# ---------------------------------------------------------------------
# (3) Run the hardened co-fit driver (does its own final bench + gate).
# ---------------------------------------------------------------------
Rscript ~/fit_v130_esi_anchor_cofit_v2.R

echo "==== v130_cofit_v2.sbatch complete ===="
