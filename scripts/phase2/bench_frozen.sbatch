#!/bin/bash
#SBATCH --job-name=bench_frozen
#SBATCH --account=puom0008
#SBATCH --time=00:40:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=bench_frozen_%j.out
# =====================================================================
# bench_frozen.sbatch -- SLURM wrapper for the CANONICAL FVS-ACD freeze harness.
#
# Submits run_bench_frozen.sh under the frozen August operational environment
# (NB_AFAC=0.579 QC_AFAC=0.111 + the rest of the frozen canon). This is the
# canonical way to reproduce cb_v12101_results.csv on the cluster.
#
# A bare `Rscript bench_parity.R` runs at the INFLATING default afac=1 and does
# NOT reproduce cb_v12101; it over-predicts dominant height and NSVB volume for
# every model. Use this wrapper.
#
# USAGE:
#   sbatch --export=ALL,MODEL_FILE=$HOME/_scripts/AcadianGY_12.10.1.r,CONFIG_TAG=cb_v12101_check bench_frozen.sbatch
#
# OUTPUT: <CONFIG_TAG>_results.csv in ~/magplot/verify + bench_frozen_<jobid>.out
# No em dashes.
# =====================================================================
set -e
source /etc/profile.d/lmod.sh
module purge
module load gcc/12.3.0 R/4.4.0
export FROZEN_MODULES_LOADED=1

# run_bench_frozen.sh location. Defaults to the verify dir where bench_parity.R
# lives; override with RUN_SCRIPT if you keep it under repos/fvs-acd/scripts/phase2.
RUN_SCRIPT="${RUN_SCRIPT:-$HOME/magplot/verify/run_bench_frozen.sh}"

: "${MODEL_FILE:?set MODEL_FILE in --export, e.g. --export=ALL,MODEL_FILE=...}"
: "${CONFIG_TAG:?set CONFIG_TAG in --export, e.g. --export=ALL,CONFIG_TAG=...}"

bash "$RUN_SCRIPT" "$MODEL_FILE" "$CONFIG_TAG"
echo "=== bench_frozen DONE: ${CONFIG_TAG}_results.csv ==="
