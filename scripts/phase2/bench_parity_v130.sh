#!/usr/bin/env bash
# =====================================================================
# bench_parity_v130.sh
# FVS-ACD v13.0 Phase 2 run recipe (Cardinal). Ready to run; DO NOT run here.
#
# Sequence:
#   (a) fit the new region esi.anchor.coef            -> ~/v130_esi_anchor_coef.csv
#   (b) build the BA-only v13.0 model file            -> ~/AcadianGY_13.0.r
#   (c) generate a one-line-changed bench_parity copy -> ~/magplot/verify/bench_parity_v130.R
#   (d) run bench_parity_v130.R for cb_v130           -> ~/magplot/verify/cb_v130_results.csv
#
# Modeled on how cb_v12101 was produced (MODEL_FILE + NB_AFAC/QC_AFAC), swapping
# MODEL_FILE to the BA-only v13.0 file, CONFIG_TAG to cb_v130, and the hardcoded
# esi.anchor.coef line to read the fitted coefficients. No em dashes.
# =====================================================================
set -euo pipefail

# --- locations (edit only if your layout differs) ---
PHASE2_DIR="${PHASE2_DIR:-$HOME/repos/fvs-acd/scripts/phase2}"   # where these Phase 2 scripts live
VERIFY_DIR="${VERIFY_DIR:-$HOME/magplot/verify}"
BASE_MODEL="${BASE_MODEL:-$HOME/_scripts/AcadianGY_12.10.1.r}"    # frozen operational base
V130_MODEL="${V130_MODEL:-$HOME/AcadianGY_13.0.r}"               # BA-only v13.0 output
COEF_CSV="${COEF_CSV:-$HOME/v130_esi_anchor_coef.csv}"

module load gcc/12.3.0 R/4.4.0

# ---------------------------------------------------------------------
# (a) Fit the new region esi.anchor.coef.
# ---------------------------------------------------------------------
Rscript "$PHASE2_DIR/fit_v130_esi_anchor.R"
test -s "$COEF_CSV" || { echo "FATAL: $COEF_CSV was not written"; exit 1; }
echo "---- fitted coefficients ----"; cat "$COEF_CSV"

# ---------------------------------------------------------------------
# (b) Build the BA-only v13.0 model file from the frozen 12.10.1 base.
#     Fails loud (exit 2/3) on any anchor mismatch; no output written then.
# ---------------------------------------------------------------------
python3 "$PHASE2_DIR/build_v130_baonly.py" "$BASE_MODEL" "$V130_MODEL"
test -s "$V130_MODEL" || { echo "FATAL: $V130_MODEL was not written (anchor guard tripped)"; exit 1; }

# Parse check the assembled model file before benchmarking.
Rscript -e 'invisible(parse(file=Sys.getenv("V130_MODEL")))' \
  && echo "parse OK: $V130_MODEL" || { echo "FATAL: $V130_MODEL does not parse"; exit 1; }

# ---------------------------------------------------------------------
# (c) Generate the runnable bench_parity_v130.R as a ONE-LINE-CHANGED copy of the
#     operational bench_parity.R. The loader logic lives in the Phase 2
#     bench_parity_v130.R (staged next to it); the operational line
#         ops$esi.anchor.coef <- list(c(NB = c(0.885, 0.01027), QC = c(0.441, 0.03783)))
#     is replaced by a source()+loader call. If your bench_parity.R spells that
#     line differently, adjust the sed pattern (it matches any assignment to
#     ops$esi.anchor.coef on a single line).
# ---------------------------------------------------------------------
cp "$PHASE2_DIR/bench_parity_v130.R" "$VERIFY_DIR/bench_parity_v130_loader.R"

sed -E 's|^[[:space:]]*ops\$esi\.anchor\.coef[[:space:]]*<-.*$|source(path.expand("~/magplot/verify/bench_parity_v130_loader.R")); ops$esi.anchor.coef <- build_esi_anchor_from_csv("~/v130_esi_anchor_coef.csv")  # v130 Phase 2: fitted coefficients|' \
  "$VERIFY_DIR/bench_parity.R" > "$VERIFY_DIR/bench_parity_v130.R"

# Confirm the substitution actually fired exactly once.
if ! grep -q "build_esi_anchor_from_csv" "$VERIFY_DIR/bench_parity_v130.R"; then
  echo "FATAL: esi.anchor.coef line not found/replaced in bench_parity.R; inspect the sed pattern"; exit 1
fi
if [ "$(grep -c 'ops\$esi\.anchor\.coef[[:space:]]*<-' "$VERIFY_DIR/bench_parity_v130.R")" -ne 1 ]; then
  echo "FATAL: expected exactly one esi.anchor.coef assignment after edit"; exit 1
fi
echo "generated $VERIFY_DIR/bench_parity_v130.R (one line changed)"

# ---------------------------------------------------------------------
# (d) Run bench_parity_v130.R for cb_v130, same env as cb_v12101 except the
#     model file and config tag.
# ---------------------------------------------------------------------
cd "$VERIFY_DIR"
export MODEL_FILE="$V130_MODEL"
export CONFIG_TAG=cb_v130
export NB_AFAC=0.579 QC_AFAC=0.111
# bench_parity defaults (unchanged): ONSET 0.30, BREAK 0.62, BG 0.020, BS 0.80,
# IRC 0.58, IRK 8, SDMAX 1.0, USE_BRMS TRUE, USE_ANCHOR TRUE, NB_BREAK 0.70, QC_BREAK 0.62.
Rscript bench_parity_v130.R
test -s "$VERIFY_DIR/cb_v130_results.csv" || { echo "FATAL: cb_v130_results.csv not produced"; exit 1; }
echo "DONE: wrote $VERIFY_DIR/cb_v130_results.csv"
