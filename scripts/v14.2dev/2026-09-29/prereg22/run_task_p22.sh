#!/bin/bash
# PREREG22 firebreather driver: one task of work/p22_taskmap. Copy of ~/jobs/v142p20/home/run_task_p20.sh (md5 80bd4290);
# changes: taskmap path, p22_env.sh, m* read from ../plan/mstar.env (P22_IMULT) for the joint arm, log tag. Refuses to
# overwrite. No coordinates. No em dashes.
set -euo pipefail
T=$1; R1=$HOME; TM=$R1/work/p22_taskmap_DATA_2026-09-29.csv
ROW=$(awk -F, -v t="$T" 'NR>1 && $1==t {print $2","$3","$4","$5","$6}' "$TM"); [ -n "$ROW" ] || { echo "task $T not in $TM"; exit 2; }
IFS=, read -r COL CHUNK SET FROM TO <<< "$ROW"
MS=/home/aaron/jobs/v142p22/plan/mstar.env; [ -e $MS ] || { echo "FATAL $MS missing"; exit 6; }; source $MS; export P22_IMULT
source $R1/p22_env.sh
p22_env "$COL" "$SET"
export CHUNK_FROM=$FROM CHUNK_TO=$TO
mkdir -p $R1/out/$COL/$SET; export CONFIG_TAG=$R1/out/$COL/$SET/c$(printf %03d $CHUNK)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE ${CONFIG_TAG}_results.csv exists"; exit 3; }
export TREE_OUT=$CONFIG_TAG
cd $HOME/magplot/verify
echo "[v142p22-fb] COL=$COL task=$T set=$SET chunk=$CHUNK rows=$FROM..$TO HTFIX_B1=${HTFIX_B1:-unset} HTFIX_B2=${HTFIX_B2:-unset} IMULT=$IMULT ING=${ING_MIN_FROM_SCORE:-unset} host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[v142p22-fb] DONE ${CONFIG_TAG}_results.csv end=$(date -Is)"
