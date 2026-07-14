#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH --job-name=v130_blendsweep
#SBATCH --time=08:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/v130_blendsweep_%j.out
#
# FVS-ACD v13.0 Phase 2, "narrow fix": blend the Test B (widen-clamp co-fit) height
# re-anchor toward the operational (identity) anchor by weight w, sweep w, and find
# the largest w that removes the POOLED volume-NSE regression (nse_no_regress and
# volume_held both TRUE at POOLED_indomain) while keeping height_toward0 TRUE at POOLED.
#
#   coef_blend = w*coef_TestB + (1-w)*(1.0, 0.0)   applied to NB and QC; ME stays (1,0).
#   w in {0.50, 0.70, 0.85, 1.00}; w=1.00 reproduces Test B as a sanity check.
#
# Runs the WIDEN-CLAMP model (AcadianGY_13.0_wideclamp.r, NOT the joint _v2.r) with the
# Test B widen band ASCALE_LO=0.80 ASCALE_HI=1.60, in-domain afac NB=0.579 QC=0.111, and
# full BA (gain=1, model default; no gain injection, matching Test B). Each w reads an
# ISOLATED per-run coef csv (v130_coef_blend.csv) and NEVER touches the shared
# v130_esi_anchor_coef.csv. Each w benches with a distinct CONFIG_TAG so no results file
# clobbers cb_v130_results.csv, and gates vs the frozen cb_v12101 baseline with distinct
# per-w output names (suffix b50, b70, b85, b100). No em dashes.
# =====================================================================
set -euo pipefail

source /etc/profile.d/lmod.sh
module load gcc/12.3.0 R/4.4.0

# --- locations ---
HOME_DIR="/users/PUOM0008/crsfaaron"
VERIFY_DIR="$HOME_DIR/magplot/verify"
MODEL_WIDECLAMP="$HOME_DIR/AcadianGY_13.0_wideclamp.r"          # widen-clamp model (Test B band)
BENCH_SRC="$VERIFY_DIR/bench_parity_v130_run.R"                 # operational runnable bench
BENCH_BLEND="$VERIFY_DIR/bench_parity_v130_blend.R"            # sed-derived bench (isolated coef csv)
COEF_BLEND="$HOME_DIR/v130_coef_blend.csv"                      # ISOLATED per-w coefs (rewritten each w)
GATE_SRC="$HOME_DIR/v130_score_gate_v2.R"                       # gate; hardcodes candidate cb_v130_results.csv
BASELINE_CSV="$VERIFY_DIR/cb_v12101_results.csv"               # frozen baseline (untouched)

# --- Test B (widen-clamp co-fit, job 12306792) converged coefs, hardcoded from
#     ~/v130_esi_anchor_coef.csv == v130_esi_anchor_coef_cofit_final.csv (values verified
#     against the .out final echo). Hardcoded so the sweep is immune to the shared csv
#     being overwritten by another job before this one runs. ---
NB_TB_INT=1.10313273404558;   NB_TB_SLP=0.005844
QC_TB_INT=0.0193386836659353; QC_TB_SLP=0.069534

mkdir -p "$VERIFY_DIR"
test -s "$MODEL_WIDECLAMP" || { echo "FATAL: widen-clamp model $MODEL_WIDECLAMP not found"; exit 1; }
test -s "$BENCH_SRC"       || { echo "FATAL: base bench $BENCH_SRC not found"; exit 1; }
test -s "$GATE_SRC"        || { echo "FATAL: gate source $GATE_SRC not found"; exit 1; }
test -s "$BASELINE_CSV"    || { echo "FATAL: baseline $BASELINE_CSV not found"; exit 1; }

# ---------------------------------------------------------------------
# (1) Generate the isolated-coef bench ONCE: base bench with ONLY the coef csv basename
#     redirected to the isolated blend csv (no BA-gain injection; full BA = model default,
#     matching Test B). Mirrors EDIT B of bench_parity_v130_bagain.sh.
# ---------------------------------------------------------------------
grep -q 'v130_esi_anchor_coef\.csv' "$BENCH_SRC" || { echo "FATAL: base bench does not read v130_esi_anchor_coef.csv"; exit 1; }
n_anchor="$(grep -c 'v130_esi_anchor_coef\.csv' "$BENCH_SRC")"
[ "$n_anchor" -eq 1 ] || { echo "FATAL: expected exactly one v130_esi_anchor_coef.csv line in base bench, found $n_anchor"; exit 1; }
sed -E 's|v130_esi_anchor_coef\.csv|v130_coef_blend.csv|g' "$BENCH_SRC" > "$BENCH_BLEND"
grep -q 'v130_coef_blend\.csv' "$BENCH_BLEND"      || { echo "FATAL: coef redirect to v130_coef_blend.csv did not fire"; exit 1; }
grep -q 'v130_esi_anchor_coef\.csv' "$BENCH_BLEND" && { echo "FATAL: bench still references shared v130_esi_anchor_coef.csv after redirect"; exit 1; }
Rscript -e 'invisible(parse(file="'"$BENCH_BLEND"'"))' && echo "parse OK: $BENCH_BLEND" || { echo "FATAL: $BENCH_BLEND does not parse"; exit 1; }
echo "generated $BENCH_BLEND (coef csv -> v130_coef_blend.csv, no gain injection, full BA)"

# ---------------------------------------------------------------------
# (2) Write the ISOLATED blended coef csv for a given w. Schema region,intercept,slope.
# ---------------------------------------------------------------------
write_blend () {
  local w="$1"
  awk -v w="$w" -v nbi="$NB_TB_INT" -v nbs="$NB_TB_SLP" -v qci="$QC_TB_INT" -v qcs="$QC_TB_SLP" 'BEGIN{
    printf "region,intercept,slope\n";
    printf "NB,%.15g,%.15g\n", w*nbi+(1-w)*1.0, w*nbs;
    printf "QC,%.15g,%.15g\n", w*qci+(1-w)*1.0, w*qcs;
    printf "ME,1,0\n";
  }' > "$COEF_BLEND"
  echo "---- blended isolated esi.anchor.coef for w=$w ($COEF_BLEND) ----"
  cat "$COEF_BLEND"
}

# ---------------------------------------------------------------------
# (3) One config = write blend csv + bench widen-clamp + gate vs cb_v12101.
#     Args: 1 w, 2 config tag, 3 short suffix for gate output names.
# ---------------------------------------------------------------------
run_config () {
  local w="$1" tag="$2" sfx="$3"
  local results_csv="$VERIFY_DIR/${tag}_results.csv"

  echo "==================================================================="
  echo "CONFIG $tag : w=$w (widen-clamp model, isolated blended coefs, full BA)"
  echo "==================================================================="

  write_blend "$w"

  # --- bench (widen-clamp model, Test B widen band, in-domain afac) ---
  cd "$VERIFY_DIR"
  MODEL_FILE="$MODEL_WIDECLAMP" \
  CONFIG_TAG="$tag" \
  ASCALE_LO=0.80 ASCALE_HI=1.60 \
  NB_AFAC=0.579 QC_AFAC=0.111 \
  Rscript "$BENCH_BLEND"
  test -s "$results_csv" || { echo "FATAL: $results_csv not produced"; exit 1; }
  echo "wrote $results_csv"

  # --- gate copy: candidate -> this config's results, baseline cb_v12101 kept,
  #     gate outputs given distinct per-config names ---
  local gate_run="$VERIFY_DIR/v130_score_gate_v2_${sfx}.R"
  sed -E \
    -e "s|cb_v130_results\.csv|${tag}_results.csv|g" \
    -e "s|scorecard_v130\.csv|scorecard_v130${sfx}.csv|g" \
    -e "s|v130_gate_delta\.csv|v130_gate_delta_${sfx}.csv|g" \
    -e "s|v130_gate_verdict\.csv|v130_gate_verdict_${sfx}.csv|g" \
    "$GATE_SRC" > "$gate_run"

  grep -q "${tag}_results\.csv" "$gate_run"      || { echo "FATAL: gate redirect to ${tag}_results.csv did not fire"; exit 1; }
  grep -q 'cb_v12101_results\.csv' "$gate_run"    || { echo "FATAL: gate baseline cb_v12101 missing after sed"; exit 1; }
  grep -q 'cb_v130_results\.csv' "$gate_run"      && { echo "FATAL: gate still points at cb_v130_results.csv after sed"; exit 1; }

  cd "$VERIFY_DIR"
  Rscript "$gate_run"
  echo "gate done for $tag"
  echo "  results  : $results_csv"
  echo "  verdict  : $VERIFY_DIR/v130_gate_verdict_${sfx}.csv"
  echo "  delta    : $VERIFY_DIR/v130_gate_delta_${sfx}.csv"
  echo "  scorecard: $VERIFY_DIR/scorecard_v130${sfx}.csv"
}

# ---------------------------------------------------------------------
# (4) The four blend weights. w=1.00 reproduces Test B (sanity check).
# ---------------------------------------------------------------------
run_config 0.50 cb_v130b50  b50
run_config 0.70 cb_v130b70  b70
run_config 0.85 cb_v130b85  b85
run_config 1.00 cb_v130b100 b100

echo "==================================================================="
echo "DONE: v13.0 narrow-fix blend sweep complete for w in 0.50 0.70 0.85 1.00."
echo "  cb_v130b50  -> v130_gate_verdict_b50.csv"
echo "  cb_v130b70  -> v130_gate_verdict_b70.csv"
echo "  cb_v130b85  -> v130_gate_verdict_b85.csv"
echo "  cb_v130b100 -> v130_gate_verdict_b100.csv  (Test B sanity)"
echo "==================================================================="
