#!/bin/bash
# PREREG49 task driver: one task of home/work/p49_taskmap. Modelled on PREREG45 run_task_p45.sh (ba24284a; taskmap lookup, chunk
# rows, OUTROOT, refusal and log lines kept in the same form so the PREREG38 retry rewrite applies) with the PREREG22
# environment in place of the QC block: the frozen p22_env.sh (a77e8117, sourced unedited) with P22_IMULT 1.5 and column
# v141LTfi, exactly as PREREG26 run_p26.sh maps v141LTfi. Changes: runner runner_p49_fb.R (the survival switch source line),
# V141_REPORT_DIR inside this job, and the arm case below. Arms:
#   v141LTfis   v141LTfi plus the survival switch, form fr, theta from the frozen fit file (md5 in logs/fit_md5.txt)
#   v141LTfis0  v141LTfi plus the survival switch at its null (form fr, theta 0): H0
# Usage: HOME=<ROOT>/home bash run_task_p49.sh <task>. P49_ROOT (default ~/jobs/v142p49) is set only in the dry run.
# Refuses to overwrite. No coordinates. No em dashes.
set -euo pipefail
T=$1; J=${P49_ROOT:-/home/aaron/jobs/v142p49}; R1=$HOME; TM=$R1/work/p49_taskmap_DATA_2026-10-26.csv
ROW=$(awk -F, -v t="$T" 'NR>1 && $1==t {print $2","$3","$4","$5","$6}' "$TM"); [ -n "$ROW" ] || { echo "task $T not in $TM"; exit 2; }
IFS=, read -r COL CHUNK SET FROM TO <<< "$ROW"
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); [ "$m" = "$2" ] || { echo "FATAL md5 $1 $m != $2"; exit 4; }; }
chk $R1/p22_env.sh a77e811715ccf4d82f96f430db36f8c5; source $R1/p22_env.sh
export P22_IMULT=1.5; p22_env v141LTfi "$SET"
export CHUNK_FROM=$FROM CHUNK_TO=$TO
OUTROOT=${OUTROOT:-out}
mkdir -p $R1/$OUTROOT/$COL/$SET; export CONFIG_TAG=$R1/$OUTROOT/$COL/$SET/c$(printf %03d $CHUNK)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE ${CONFIG_TAG}_results.csv exists"; exit 3; }
export V141_REPORT_DIR=$R1/tables/counters_$COL
unset P49_SF_OVERLAY SF_FORM SF_THETA SF_TRACE || true
OV=$J/scripts/sf_overlay_p49.R; chk $OV 46114af4f5d63f5763a210c23639926f
case "$COL" in
  v141LTfis) FF=$J/fit/gyr142-p49-sffr-fit_DATA_2026-10-26.csv; chk $FF $(cut -d' ' -f1 $J/logs/fit_md5.txt)
    TH=$(awk -F, 'NR==1{for(i=1;i<=NF;i++) if($i=="estimate") c=i} NR==2{print $c}' $FF); [[ "$TH" =~ ^[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?$ ]] || { echo "FATAL fit value $TH"; exit 2; }
    export P49_SF_OVERLAY=$OV SF_FORM=fr SF_THETA=$TH ;;
  v141LTfis0) export P49_SF_OVERLAY=$OV SF_FORM=fr SF_THETA=0 ;;
  *) echo "bad COL $COL"; exit 2 ;;
esac
if [ -n "${P49_TRACE:-}" ]; then export SF_TRACE=$P49_TRACE; fi
RUNNER=$R1/runner_p49_fb.R; chk $RUNNER 28d533bd090d98afbc57c33d615d1110
export TREE_OUT=$CONFIG_TAG
cd $R1/magplot/verify
echo "[v142p49-fb] COL=$COL task=$T set=$SET chunk=$CHUNK rows=$FROM..$TO HTFIX_B1=${HTFIX_B1:-unset} HTFIX_B2=${HTFIX_B2:-unset} IMULT=$IMULT ING=${ING_MIN_FROM_SCORE:-unset} SF_FORM=${SF_FORM:-unset} SF_THETA=${SF_THETA:-unset} host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[v142p49-fb] DONE ${CONFIG_TAG}_results.csv end=$(date -Is)"
