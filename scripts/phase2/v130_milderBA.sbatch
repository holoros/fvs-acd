#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH --job-name=v130_milderBA
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/v130_milderBA_%j.out
#
# FVS-ACD v13.0 Phase 2, Test C (milder BA). Ready to run on Cardinal; DO NOT run here.
#
# HYPOTHESIS
# ----------
# The joint candidate (refit dominant-height anchor + BA post-mortality correction)
# is the best variant but PARKS: correcting basal area upward inflates dominant
# height (positively coupled), and the height overshoot fails the gate. Test C
# applies only a PARTIAL BA correction via the bounded gain knob ops$ba.anchor.gain
# (read at RUN TIME from the ops list; default 1). A gain below 1 shrinks the BA
# nudge and, with it, the coupled height inflation, trading some BA improvement for
# a smaller height overshoot. This job re-gates the JOINT model at two gains.
#
# WHAT IT RUNS
# ------------
# The SAME BA-fixed joint model file, ~/AcadianGY_13.0_v2.r, benched twice:
#   config 1: BA_GAIN=0.5, CONFIG_TAG=cb_v130c05  -> cb_v130c05_results.csv
#   config 2: BA_GAIN=0.7, CONFIG_TAG=cb_v130c07  -> cb_v130c07_results.csv
# Both use the ISOLATED refit-height coefficients (v130_coef_jointrefit.csv) so the
# height leg matches the joint, and each is gated against the frozen baseline
# cb_v12101. Result files carry the config tag, so neither clobbers the joint
# candidate's cb_v130_results.csv.
#
# The bench is bench_parity_v130_bagain.R, generated once by
# bench_parity_v130_bagain.sh: it injects ops$ba.anchor.gain <- as.numeric(
# Sys.getenv("BA_GAIN","1")) after the model is sourced and redirects the coef csv
# to the isolated one. Only BA_GAIN and CONFIG_TAG change between the two configs.
# No em dashes.
# =====================================================================

set -euo pipefail

source /etc/profile.d/lmod.sh
module load gcc/12.3.0 R/4.4.0

# --- locations ---
HOME_DIR="/users/PUOM0008/crsfaaron"
PHASE2_DIR="${PHASE2_DIR:-$HOME_DIR/repos/fvs-acd/scripts/phase2}"
VERIFY_DIR="${VERIFY_DIR:-$HOME_DIR/magplot/verify}"
MODEL_FILE_JOINT="${MODEL_FILE_JOINT:-$HOME_DIR/AcadianGY_13.0_v2.r}"   # BA-fixed JOINT model (reused)
COEF_JOINTREFIT="$HOME_DIR/v130_coef_jointrefit.csv"                    # isolated refit-height coefs
BENCH_GAIN="$VERIFY_DIR/bench_parity_v130_bagain.R"                     # sed-derived bench (gain + isolated csv)
GATE_SRC="${GATE_SRC:-$HOME_DIR/v130_score_gate_v2.R}"                  # gate; hardcodes candidate cb_v130_results.csv
BASELINE_CSV="$VERIFY_DIR/cb_v12101_results.csv"                        # frozen baseline (untouched)

mkdir -p "$VERIFY_DIR"

test -s "$MODEL_FILE_JOINT" || { echo "FATAL: joint model $MODEL_FILE_JOINT not found"; exit 1; }
test -s "$GATE_SRC"        || { echo "FATAL: gate source $GATE_SRC not found"; exit 1; }
test -s "$BASELINE_CSV"    || { echo "FATAL: baseline $BASELINE_CSV not found"; exit 1; }

# ---------------------------------------------------------------------
# (1) Write the ISOLATED refit-height coefficients. This experiment reads ONLY
#     this csv (the bench is redirected to it) and never touches the shared
#     ~/v130_esi_anchor_coef.csv. Schema is region,intercept,slope (loader/bench
#     contract). These are the v13.0 joint refit values so height matches the joint.
# ---------------------------------------------------------------------
cat > "$COEF_JOINTREFIT" <<'CSV'
region,intercept,slope
NB,0.997968,0.005844
QC,-0.153678,0.069534
ME,1.0,0.0
CSV
echo "---- isolated refit-height esi.anchor.coef pinned in $COEF_JOINTREFIT ----"
cat "$COEF_JOINTREFIT"

# ---------------------------------------------------------------------
# (2) Generate the sed-derived bench: injects the runtime BA_GAIN line after the
#     model is sourced and redirects the coef csv to the isolated one. Verified,
#     parse-checked, and FATAL on any miss inside the generator.
# ---------------------------------------------------------------------
test -s "$PHASE2_DIR/bench_parity_v130_bagain.sh" || { echo "FATAL: generator bench_parity_v130_bagain.sh not found in $PHASE2_DIR"; exit 1; }
VERIFY_DIR="$VERIFY_DIR" BENCH_OUT="$BENCH_GAIN" bash "$PHASE2_DIR/bench_parity_v130_bagain.sh"
test -s "$BENCH_GAIN" || { echo "FATAL: $BENCH_GAIN was not generated"; exit 1; }

# ---------------------------------------------------------------------
# (3) One config = one bench run at a given gain + one gate vs cb_v12101.
#     Args: 1 gain, 2 config tag, 3 short suffix for gate output names.
# ---------------------------------------------------------------------
run_config () {
  local gain="$1" tag="$2" sfx="$3"
  local results_csv="$VERIFY_DIR/${tag}_results.csv"

  echo "==================================================================="
  echo "CONFIG $tag : BA_GAIN=$gain (joint model, isolated refit-height coefs)"
  echo "==================================================================="

  # --- bench ---
  cd "$VERIFY_DIR"
  MODEL_FILE="$MODEL_FILE_JOINT" \
  CONFIG_TAG="$tag" \
  BA_GAIN="$gain" \
  NB_AFAC=0.579 QC_AFAC=0.111 \
  Rscript "$BENCH_GAIN"
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
# (4) The two configs.
# ---------------------------------------------------------------------
run_config 0.5 cb_v130c05 c05
run_config 0.7 cb_v130c07 c07

echo "==================================================================="
echo "DONE: Test C milder-BA re-gate complete for BA_GAIN 0.5 and 0.7."
echo "  cb_v130c05 -> v130_gate_verdict_c05.csv"
echo "  cb_v130c07 -> v130_gate_verdict_c07.csv"
echo "==================================================================="
