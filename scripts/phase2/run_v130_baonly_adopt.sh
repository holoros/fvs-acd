#!/usr/bin/env bash
# =====================================================================
# run_v130_baonly_adopt.sh
# FVS-ACD v13.0 Phase 2: BA-ONLY conservative adoption candidate (cb_v130ba).
#
# Banks the validated basal-area post-mortality correction and DEFERS the v13.0
# dominant-height re-anchor (the joint height + BA candidate PARKED at the gate
# on the height leg; the BA leg validated, bias toward 0 in 4 of 5 subsets, the
# earlier sign-flip fixed). This candidate ships the BA correction ONLY and holds
# dominant height at OPERATIONAL v12.10.1 behavior.
#
# HOW HEIGHT IS PINNED TO v12.10.1
# --------------------------------
# build_v130_baonly_v2.py applies ONLY the BA net-increment anchor and injects
# NO height coefficients (its EDIT 1, the Chapman-Richards height swap, is
# intentionally omitted and a build-time guard asserts no height tokens are
# present). Dominant height is therefore controlled entirely at run time by the
# harness-native ops$esi.anchor.coef hook, which the runnable bench
# ~/bench_parity_v130_run.R reads from ~/v130_esi_anchor_coef.csv. This wrapper
# writes the OPERATIONAL v12.10.1 region coefficients into that CSV (NOT the
# v13.0 refit values, and it does NOT run fit_v130_esi_anchor.R, which would
# produce the refit values). Net effect: the height path equals shipped
# v12.10.1 exactly, while the model file carries the BA correction.
#
# Sequence:
#   (a) write OPERATIONAL v12.10.1 esi.anchor.coef -> ~/v130_esi_anchor_coef.csv
#   (b) build BA-only model from ~/AcadianGY_12.10.2.r -> ~/AcadianGY_13.0_baonly.r
#       (fails loud on any anchor mismatch; no output written then)
#   (c) parse-check the built model
#   (d) run ~/bench_parity_v130_run.R with CONFIG_TAG cb_v130ba -> cb_v130ba_results.csv
#   (e) gate cb_v130ba vs cb_v12101 via a redirected copy of v130_score_gate_v2.R
#
# The results file is cb_v130ba_results.csv so it does NOT clobber the joint
# candidate's cb_v130_results.csv, and the gate copy writes *_baonly outputs so
# it does not clobber the joint gate outputs either. No em dashes.
# =====================================================================
set -euo pipefail

# --- locations (edit only if your layout differs) ---
PHASE2_DIR="${PHASE2_DIR:-$HOME/repos/fvs-acd/scripts/phase2}"
VERIFY_DIR="${VERIFY_DIR:-$HOME/magplot/verify}"
BASE_MODEL="${BASE_MODEL:-$HOME/AcadianGY_12.10.2.r}"        # base for the BA-only build
V130_MODEL="${V130_MODEL:-$HOME/AcadianGY_13.0_baonly.r}"    # BA-only output
COEF_CSV="${COEF_CSV:-$HOME/v130_esi_anchor_coef.csv}"       # runtime height anchor, read by the bench
BENCH_RUN="${BENCH_RUN:-$HOME/bench_parity_v130_run.R}"      # runnable bench; reads COEF_CSV
GATE_SRC="${GATE_SRC:-$PHASE2_DIR/v130_score_gate_v2.R}"     # gate source (baseline cb_v12101)
CONFIG_TAG="${CONFIG_TAG:-cb_v130ba}"
RESULTS_CSV="$VERIFY_DIR/${CONFIG_TAG}_results.csv"

mkdir -p "$VERIFY_DIR"

# ---------------------------------------------------------------------
# (a) Pin the dominant-height anchor to the OPERATIONAL v12.10.1 values.
#     These are the shipped ascale lines. Do NOT substitute the v13.0 refit
#     (NB 0.997968/0.005844, QC -0.153678/0.069534) and do NOT run
#     fit_v130_esi_anchor.R, which would write the refit values.
#     Schema is exactly region,intercept,slope (the loader/bench contract).
# ---------------------------------------------------------------------
cat > "$COEF_CSV" <<'CSV'
region,intercept,slope
NB,0.885,0.01027
QC,0.441,0.03783
ME,1.0,0.0
CSV
echo "---- operational v12.10.1 esi.anchor.coef pinned in $COEF_CSV ----"
cat "$COEF_CSV"

# ---------------------------------------------------------------------
# (b) Build the BA-only v13.0 model from the 12.10.2 base.
#     build_v130_baonly_v2.py exits 2/3 without writing on any anchor/sanity
#     mismatch, and its sanity guard asserts NO height edit is present.
# ---------------------------------------------------------------------
test -s "$BASE_MODEL" || { echo "FATAL: base model $BASE_MODEL not found"; exit 1; }
python3 "$PHASE2_DIR/build_v130_baonly_v2.py" "$BASE_MODEL" "$V130_MODEL"
test -s "$V130_MODEL" || { echo "FATAL: $V130_MODEL was not written (anchor/sanity guard tripped)"; exit 1; }

# ---------------------------------------------------------------------
# (c) Parse-check the assembled model file before benchmarking.
# ---------------------------------------------------------------------
V130_MODEL="$V130_MODEL" Rscript -e 'invisible(parse(file=Sys.getenv("V130_MODEL")))' \
  && echo "parse OK: $V130_MODEL" || { echo "FATAL: $V130_MODEL does not parse"; exit 1; }

# ---------------------------------------------------------------------
# (d) Run the runnable bench for cb_v130ba. Same env as cb_v12101 except the
#     model file and the config tag. The bench reads the pinned COEF_CSV at run
#     time, so the height behavior is operational v12.10.1.
# ---------------------------------------------------------------------
test -s "$BENCH_RUN" || { echo "FATAL: runnable bench $BENCH_RUN not found"; exit 1; }
cd "$VERIFY_DIR"
export MODEL_FILE="$V130_MODEL"
export CONFIG_TAG
export NB_AFAC=0.579 QC_AFAC=0.111
Rscript "$BENCH_RUN"
test -s "$RESULTS_CSV" || { echo "FATAL: $RESULTS_CSV not produced"; exit 1; }
echo "wrote $RESULTS_CSV"

# ---------------------------------------------------------------------
# (e) Gate cb_v130ba against cb_v12101. v130_score_gate_v2.R hardcodes the
#     candidate as cb_v130_results.csv, so generate a redirected copy that reads
#     cb_v130ba_results.csv and writes *_baonly output files. The baseline
#     (cb_v12101_results.csv) is left untouched.
# ---------------------------------------------------------------------
test -s "$GATE_SRC" || { echo "FATAL: gate source $GATE_SRC not found"; exit 1; }
GATE_RUN="$VERIFY_DIR/v130_score_gate_v2_baonly.R"
sed -E \
  -e 's|cb_v130_results\.csv|cb_v130ba_results.csv|g' \
  -e 's|scorecard_v130\.csv|scorecard_v130ba.csv|g' \
  -e 's|v130_gate_delta\.csv|v130_gate_delta_baonly.csv|g' \
  -e 's|v130_gate_verdict\.csv|v130_gate_verdict_baonly.csv|g' \
  "$GATE_SRC" > "$GATE_RUN"
grep -q 'cb_v130ba_results\.csv' "$GATE_RUN" || { echo "FATAL: gate redirect to cb_v130ba_results.csv did not fire"; exit 1; }
grep -q 'cb_v12101_results\.csv' "$GATE_RUN" || { echo "FATAL: gate baseline cb_v12101 missing after sed"; exit 1; }

cd "$VERIFY_DIR"
Rscript "$GATE_RUN"
echo "DONE: BA-only adoption bench + gate complete."
echo "  results : $RESULTS_CSV"
echo "  verdict : $VERIFY_DIR/v130_gate_verdict_baonly.csv"
echo "  delta   : $VERIFY_DIR/v130_gate_delta_baonly.csv"
echo "  scorecard: $VERIFY_DIR/scorecard_v130ba.csv"
