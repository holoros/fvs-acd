#!/usr/bin/env bash
# =====================================================================
# bench_parity_v130_bagain.sh
# FVS-ACD v13.0 Phase 2, Test C (milder BA). Ready to run on Cardinal; DO NOT run here.
#
# Generates a sed-derived runnable bench, ~/magplot/verify/bench_parity_v130_bagain.R,
# from the operational runnable bench ~/bench_parity_v130_run.R (symlinked at
# ~/magplot/verify/bench_parity_v130_run.R). This mirrors how bench_parity_v130.sh
# produces bench_parity_v130.R: a small, verified set of sed edits, nothing else.
#
# WHY THIS EXISTS
# ---------------
# The joint candidate (refit dominant-height anchor + BA post-mortality correction)
# is the best variant but PARKS: correcting basal area upward inflates dominant
# height (the two are positively coupled), and the height overshoot fails the gate.
# Test C applies only a PARTIAL BA correction via the bounded gain knob
# ops$ba.anchor.gain (built into AcadianGY_13.0_v2.r; read at RUN TIME from the ops
# list, defaulting to 1). A gain below 1 damps the solved survivor-increment scale
# toward 1, so the BA nudge, and therefore the coupled height inflation, is smaller.
#
# THE TWO EDITS (verified to fire; FATAL otherwise, nothing written on failure)
# ----------------------------------------------------------------------------
#  EDIT A (gain injection): insert, immediately AFTER the ops$esi.anchor.coef
#          assignment line (the build_esi_anchor_from_csv line), a line
#              ops$ba.anchor.gain <- as.numeric(Sys.getenv("BA_GAIN","1"))
#          Rationale for anchoring on the esi.anchor.coef line rather than the raw
#          model source() line: that line is guaranteed present in the runnable
#          bench (bench_parity_v130.sh inserts it), it runs AFTER the model is
#          sourced AND after ops is constructed, and it is the LAST ops field edit
#          before the run, so the gain assignment lands on the existing ops object
#          and cannot be wiped by a later ops rebuild. The model then reads
#          ops$ba.anchor.gain at call time. BA_GAIN is supplied per config by the
#          sbatch (0.5 and 0.7); absent, the model default of 1 applies.
#
#  EDIT B (coef redirect): rewrite the coefficient CSV basename
#              v130_esi_anchor_coef.csv  ->  v130_coef_jointrefit.csv
#          so this experiment reads the ISOLATED refit-height coefficients and
#          never touches the shared ~/v130_esi_anchor_coef.csv. The redirect is
#          basename-global, so it is agnostic to whether the bench spells the path
#          with a tilde (~/...) or absolute (/users/PUOM0008/crsfaaron/...).
#
# Everything else in the bench (MODEL_FILE, CONFIG_TAG, NB_AFAC/QC_AFAC, every
# other ops assignment, the run and the write of cb_<TAG>_results.csv) is UNCHANGED.
# No em dashes.
# =====================================================================
set -euo pipefail

# --- locations (edit only if your layout differs) ---
VERIFY_DIR="${VERIFY_DIR:-$HOME/magplot/verify}"
# Prefer the verify-dir copy/symlink; fall back to the home symlink.
BENCH_SRC="${BENCH_SRC:-}"
if [ -z "$BENCH_SRC" ]; then
  if   [ -s "$VERIFY_DIR/bench_parity_v130_run.R" ]; then BENCH_SRC="$VERIFY_DIR/bench_parity_v130_run.R"
  elif [ -s "$HOME/bench_parity_v130_run.R" ];        then BENCH_SRC="$HOME/bench_parity_v130_run.R"
  else echo "FATAL: runnable bench bench_parity_v130_run.R not found in $VERIFY_DIR or $HOME"; exit 1
  fi
fi
BENCH_OUT="${BENCH_OUT:-$VERIFY_DIR/bench_parity_v130_bagain.R}"

test -s "$BENCH_SRC" || { echo "FATAL: source bench $BENCH_SRC not found/empty"; exit 1; }

# Sanity: the source bench must contain the two tokens we edit.
grep -q 'build_esi_anchor_from_csv' "$BENCH_SRC" || {
  echo "FATAL: $BENCH_SRC has no build_esi_anchor_from_csv line to anchor the gain injection on"; exit 1; }
grep -q 'v130_esi_anchor_coef\.csv' "$BENCH_SRC" || {
  echo "FATAL: $BENCH_SRC does not read v130_esi_anchor_coef.csv; cannot redirect to the isolated csv"; exit 1; }

# The build_esi_anchor_from_csv line must appear exactly once, so the gain line is
# inserted exactly once.
n_anchor="$(grep -c 'build_esi_anchor_from_csv' "$BENCH_SRC")"
if [ "$n_anchor" -ne 1 ]; then
  echo "FATAL: expected exactly one build_esi_anchor_from_csv line in $BENCH_SRC, found $n_anchor"; exit 1
fi

mkdir -p "$VERIFY_DIR"
TMP="$(mktemp)"

# EDIT B first (basename redirect to the isolated refit-height csv).
sed -E 's|v130_esi_anchor_coef\.csv|v130_coef_jointrefit.csv|g' "$BENCH_SRC" > "$TMP"

# EDIT A (gain injection immediately after the esi.anchor.coef line).
sed -E '/build_esi_anchor_from_csv/a ops$ba.anchor.gain <- as.numeric(Sys.getenv("BA_GAIN","1"))  # v130 Test C milder BA: partial BA anchor gain (runtime, read by AcadianGYOneStand)' \
  "$TMP" > "$BENCH_OUT"
rm -f "$TMP"

# --- verify both edits fired exactly as intended ---
if [ "$(grep -c 'ops\$ba\.anchor\.gain <- as.numeric(Sys.getenv("BA_GAIN"' "$BENCH_OUT")" -ne 1 ]; then
  echo "FATAL: gain injection did not fire exactly once in $BENCH_OUT"; exit 1
fi
if ! grep -q 'v130_coef_jointrefit\.csv' "$BENCH_OUT"; then
  echo "FATAL: coef redirect to v130_coef_jointrefit.csv did not fire in $BENCH_OUT"; exit 1
fi
if grep -q 'v130_esi_anchor_coef\.csv' "$BENCH_OUT"; then
  echo "FATAL: $BENCH_OUT still references the shared v130_esi_anchor_coef.csv after redirect"; exit 1
fi

# Parse-check the generated bench.
BENCH_OUT="$BENCH_OUT" Rscript -e 'invisible(parse(file=Sys.getenv("BENCH_OUT")))' \
  && echo "parse OK: $BENCH_OUT" || { echo "FATAL: $BENCH_OUT does not parse"; exit 1; }

echo "generated $BENCH_OUT"
echo "  gain line injected after the esi.anchor.coef assignment"
echo "  coef csv redirected to v130_coef_jointrefit.csv (isolated)"
