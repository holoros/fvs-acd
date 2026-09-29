#!/bin/bash
# PREREG20 firebreather driver: one task of work/p20_taskmap. Derived from ~/jobs/v142p17/scripts/run_task_p17.sh (md5
# b1eb7e04); the environment block is that file's verbatim (the bench141 v141LT block rebased to this bundle), except:
# IMULT stays at the bench141 value 2.5 and ING_MIN_FROM_SCORE is NOT set (base is v141LT, 14.1 as shipped, no ingrowth
# matching); the runner is the PREREG20 copy runner_p20_fb.R (diff in ../runner_p20_vs_htfix.diff); HTFIX_B is unset and
# HTFIX_B1/HTFIX_B2 carry the PREREG20 parameters for the arm and the Maine control; memat_c gets its bench141 TST_FILE.
# Refuses to overwrite. No coordinates. No em dashes.
set -euo pipefail
T=$1; R1=$HOME; TM=$R1/work/p20_taskmap_DATA_2026-09-28.csv
ROW=$(awk -F, -v t="$T" 'NR>1 && $1==t {print $2","$3","$4","$5","$6}' "$TM"); [ -n "$ROW" ] || { echo "task $T not in $TM"; exit 2; }
IFS=, read -r COL CHUNK SET FROM TO <<< "$ROW"
source $R1/p20_env.sh
p20_env "$COL" "$SET"
export CHUNK_FROM=$FROM CHUNK_TO=$TO
mkdir -p $R1/out/$COL/$SET; export CONFIG_TAG=$R1/out/$COL/$SET/c$(printf %03d $CHUNK)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE ${CONFIG_TAG}_results.csv exists"; exit 3; }
export TREE_OUT=$CONFIG_TAG
cd $HOME/magplot/verify
echo "[v142p20-fb] COL=$COL task=$T set=$SET chunk=$CHUNK rows=$FROM..$TO HTFIX_B1=${HTFIX_B1:-unset} HTFIX_B2=${HTFIX_B2:-unset} IMULT=$IMULT ING=${ING_MIN_FROM_SCORE:-unset} host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[v142p20-fb] DONE ${CONFIG_TAG}_results.csv end=$(date -Is)"
