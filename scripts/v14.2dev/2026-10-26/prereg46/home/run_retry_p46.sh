#!/bin/bash
# PREREG38 retry driver (copy of PREREG28b run_retry_p28b.sh md5 775256d6; driver name and md5 only). PREREG28 retry driver (copy of PREREG23 run_retry_p23.sh, itself a copy of PREREG19 run_retry_p19.sh): one stand, selected BY NAME (STAND_KEEP_FILE), after a host time limit failure. The environment is
# run_task_p23.sh (itself a copy of run_task_p19.sh md5 ac029e4e) verbatim, sourced through a copy with the taskmap and chunk lines replaced. Never by pairs
# row. Usage: HOME=<bundle home> bash run_retry_p19.sh <COL> <SET> <STAND> <attempt>. No coordinates. No em dashes.
set -euo pipefail
COL=$1; SET=$2; ST=$3; K=$4; R1=$HOME; ID=$(printf %s "$ST" | cksum | cut -d' ' -f1)
D=$R1/../scripts/run_task_p46.sh; echo "2e36f48b6afacecc863a2dd8fa74b56e  $D" | md5sum -c --quiet - || { echo "FATAL driver md5"; exit 4; }
mkdir -p $R1/work/retry_keep; KF=$R1/work/retry_keep/${COL}_${SET}_${ID}.csv; printf 'STAND\n%s\n' "$ST" > $KF
TMP=$R1/work/retry_keep/drv_${COL}_${SET}_${ID}_a$K.sh
## replace the taskmap lookup with the arguments, drop the chunk rows, keep the stand file, and name the output by stand id
sed -e "s|^ROW=.*|ROW=\"$COL,0,$SET,0,0\"|" -e "s|^export CHUNK_FROM=.*|unset CHUNK_FROM CHUNK_TO \|\| true; export STAND_KEEP_FILE=$KF|" \
    -e "s|c\$(printf %03d \$CHUNK)|c$ID|" $D > $TMP
grep -q "STAND_KEEP_FILE=$KF" $TMP && grep -q "c$ID" $TMP || { echo "FATAL driver rewrite failed"; exit 6; }
OUTROOT=out_retry_a$K bash $TMP retry
CT=$R1/out_retry_a$K/$COL/$SET/c$ID
got=$(sed -n 2p ${CT}_results.csv | cut -d, -f1 | tr -d '"')
[ "$got" = "$ST" ] || { for f in ${CT}_*; do mv "$f" "${f}_BADSTAND"; done; echo "FATAL retry ran $got, wanted $ST"; exit 9; }
echo "[v142p46-retry] DONE ${CT}_results.csv attempt=$K end=$(date -Is)"
