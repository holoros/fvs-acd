#!/bin/bash
# PREREG30 firebreather driver: one task of work/p30_taskmap (fold B stands of one set, selected BY NAME via STAND_KEEP_FILE).
# Copy of ~/jobs/v142p20/home/run_task_p20.sh (md5 80bd4290) except: the stand selection is STAND_KEEP_FILE (no CHUNK_FROM or
# CHUNK_TO) and the taskmap has a keep file column. Environment is the PREREG20 p20_env.sh unedited, column g0_off (height
# correction unset, IMULT 2.5, no ingrowth matching: v141LT). Refuses to overwrite. No coordinates. No em dashes.
set -euo pipefail
T=$1; R1=$HOME; TM=$R1/work/p30_taskmap_DATA_2026-09-30.csv
ROW=$(awk -F, -v t="$T" 'NR>1 && $1==t {print $2","$3","$4","$5}' "$TM"); [ -n "$ROW" ] || { echo "task $T not in $TM"; exit 2; }
IFS=, read -r COL CHUNK SET KEEP <<< "$ROW"
source $R1/p20_env.sh
p20_env "$COL" "$SET"
unset CHUNK_FROM CHUNK_TO || true; export STAND_KEEP_FILE=$KEEP
mkdir -p $R1/out/$COL/$SET; export CONFIG_TAG=$R1/out/$COL/$SET/c$(printf %03d $CHUNK)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE ${CONFIG_TAG}_results.csv exists"; exit 3; }
export TREE_OUT=$CONFIG_TAG
cd $HOME/magplot/verify
echo "[v142p30-fb] COL=$COL task=$T set=$SET chunk=$CHUNK keep=$KEEP HTFIX_B1=${HTFIX_B1:-unset} HTFIX_B2=${HTFIX_B2:-unset} IMULT=$IMULT ING=${ING_MIN_FROM_SCORE:-unset} host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[v142p30-fb] DONE ${CONFIG_TAG}_results.csv end=$(date -Is)"
