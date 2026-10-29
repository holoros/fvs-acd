#!/bin/bash
# PREREG22 retry driver: one stand, selected BY NAME (STAND_KEEP_FILE), after a host time limit failure. Copy of
# ~/jobs/v142p20/home/run_retry_p20.sh; changes: p22_env.sh and m* from ../plan/mstar.env. Never by pairs row.
set -euo pipefail
COL=$1; SET=$2; ST=$3; K=$4; R1=$HOME; ID=$(printf %s "$ST" | cksum | cut -d' ' -f1)
MS=/home/aaron/jobs/v142p22/plan/mstar.env; [ -e $MS ] || { echo "FATAL $MS missing"; exit 6; }; source $MS; export P22_IMULT
source $R1/p22_env.sh; p22_env "$COL" "$SET"
unset CHUNK_FROM CHUNK_TO || true
mkdir -p $R1/work/retry_keep; KF=$R1/work/retry_keep/${COL}_${SET}_${ID}.csv; printf 'STAND\n%s\n' "$ST" > $KF; export STAND_KEEP_FILE=$KF
mkdir -p $R1/out_retry_a$K/$COL/$SET; export CONFIG_TAG=$R1/out_retry_a$K/$COL/$SET/c$ID
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE ${CONFIG_TAG}_results.csv exists"; exit 3; }
export TREE_OUT=$CONFIG_TAG
cd $HOME/magplot/verify
echo "[v142p22-retry] attempt=$K COL=$COL stand=$ST id=$ID set=$SET HTFIX_B1=${HTFIX_B1:-unset} IMULT=$IMULT ING=${ING_MIN_FROM_SCORE:-unset} host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
got=$(sed -n 2p ${CONFIG_TAG}_results.csv | cut -d, -f1 | tr -d '"')
[ "$got" = "$ST" ] || { for f in ${CONFIG_TAG}_*; do mv "$f" "${f}_BADSTAND"; done; echo "FATAL retry ran $got, wanted $ST"; exit 9; }
echo "[v142p22-retry] DONE ${CONFIG_TAG}_results.csv end=$(date -Is)"
