#!/usr/bin/env bash
#SBATCH --account=PUOM0008
#SBATCH --job-name=v130_cofit
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=10:00:00
#SBATCH --output=/users/PUOM0008/crsfaaron/v130_cofit_%j.out
# =====================================================================
# v130_cofit.sbatch
# FVS-ACD v13.0 Phase 2: iterative co-calibration of the region
# esi.anchor.coef with the BA post-mortality correction ACTIVE, then a final
# bench + gate so the settled candidate gets a captured verdict.
#
# Sequence:
#   (a) build the BA-only v13.0 model file from AcadianGY_12.10.2.r
#   (b) run the co-fit driver (3 damped Gauss-Seidel iterations; each writes the
#       region coefs, benches the full model, reads per-region in-domain TOPHT
#       bias, and nudges the intercepts). Writes the settled coefs to
#       ~/v130_esi_anchor_coef.csv and the per-iteration trail to
#       ~/v130_cofit_log.csv. The driver's own final bench + gate is disabled
#       here (COFIT_FINAL_GATE=0) so exactly one final pass runs, below.
#   (c) final bench with the settled coefs -> ~/magplot/verify/cb_v130_results.csv
#   (d) final gate vs cb_v12101            -> ~/magplot/verify/v130_gate_verdict.csv
#
# Modeled on bench_parity_v130.sh: same MODEL_FILE + NB_AFAC/QC_AFAC env, same
# CONFIG_TAG cb_v130, same gate baseline cb_v12101. No em dashes.
# =====================================================================
set -euo pipefail

HOME_DIR=/users/PUOM0008/crsfaaron
PHASE2_DIR="${PHASE2_DIR:-$HOME_DIR/repos/fvs-acd/scripts/phase2}"
VERIFY_DIR="${VERIFY_DIR:-$HOME_DIR/magplot/verify}"
BASE_MODEL="${BASE_MODEL:-$HOME_DIR/AcadianGY_12.10.2.r}"
V130_MODEL="${V130_MODEL:-$HOME_DIR/AcadianGY_13.0.r}"
COEF_CSV="${COEF_CSV:-$HOME_DIR/v130_esi_anchor_coef.csv}"
BENCH_RUN="${BENCH_RUN:-$HOME_DIR/bench_parity_v130_run.R}"
GATE="${GATE:-$HOME_DIR/v130_score_gate_v2.R}"

# Module order matters on Cardinal: toolchain, geospatial stack, then R.
module load gcc/12.3.0
module load gdal
module load geos
module load proj
module load R/4.4.0

# ---------------------------------------------------------------------
# (a) Build the BA-only v13.0 model file. Fails loud (exit 2/3) on any anchor
#     mismatch and writes nothing then. The height correction is NOT a model
#     edit; it is delivered at run time through the fitted esi.anchor.coef.
# ---------------------------------------------------------------------
python3 "$PHASE2_DIR/build_v130_baonly_v2.py" "$BASE_MODEL" "$V130_MODEL"
test -s "$V130_MODEL" || { echo "FATAL: $V130_MODEL was not written (anchor guard tripped)"; exit 1; }
Rscript -e 'invisible(parse(file=Sys.getenv("V130_MODEL")))' \
  && echo "parse OK: $V130_MODEL" || { echo "FATAL: $V130_MODEL does not parse"; exit 1; }

# ---------------------------------------------------------------------
# (b) Run the co-fit driver. The model is already built, so COFIT_BUILD=0.
#     COFIT_FINAL_GATE=0 defers the single final bench + gate to steps (c)/(d).
#     Tune the loop with COFIT_ITERS / COFIT_GAIN / COFIT_MAX_STEP; set
#     COFIT_NUDGE_SLOPE=1 to also move slope.
# ---------------------------------------------------------------------
export MODEL_FILE="$V130_MODEL"
export NB_AFAC=0.579 QC_AFAC=0.111
export COFIT_ITERS="${COFIT_ITERS:-3}"
export COFIT_GAIN="${COFIT_GAIN:-0.9}"
export COFIT_MAX_STEP="${COFIT_MAX_STEP:-0.15}"
export COFIT_NUDGE_SLOPE="${COFIT_NUDGE_SLOPE:-0}"
export COFIT_START_FROM_CSV="${COFIT_START_FROM_CSV:-1}"
export COFIT_BUILD=0
export COFIT_FINAL_GATE=0

cd "$VERIFY_DIR"
Rscript "$PHASE2_DIR/fit_v130_esi_anchor_cofit.R"
test -s "$COEF_CSV" || { echo "FATAL: $COEF_CSV was not written by the co-fit driver"; exit 1; }
echo "---- settled esi.anchor.coef ----"; cat "$COEF_CSV"

# ---------------------------------------------------------------------
# (c) Final bench with the settled coefficients (same env as cb_v12101 except
#     the v13.0 model file and the cb_v130 tag). Reads the settled COEF_CSV.
# ---------------------------------------------------------------------
export CONFIG_TAG=cb_v130
Rscript "$BENCH_RUN"
test -s "$VERIFY_DIR/cb_v130_results.csv" || { echo "FATAL: cb_v130_results.csv not produced"; exit 1; }

# ---------------------------------------------------------------------
# (d) Final gate vs cb_v12101. Writes scorecard_v130.csv, v130_gate_delta.csv,
#     and v130_gate_verdict.csv, and prints ADOPT_PENDING or PARK.
# ---------------------------------------------------------------------
Rscript "$GATE"
echo "==== v130_cofit.sbatch complete ===="
echo "settled coefs:      $COEF_CSV"
echo "per-iteration log:  $HOME_DIR/v130_cofit_log.csv"
echo "final verdict:      $VERIFY_DIR/v130_gate_verdict.csv"
