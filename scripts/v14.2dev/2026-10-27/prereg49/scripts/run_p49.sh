#!/bin/bash
# PREREG49 stage 2 task wrapper: PREREG26 run_p26.sh (e1a1371f) with the job root, the driver (driver_p49.R: driver_p26 with the
# ported slgrid branch and the survival switch source line), the bundle copy as HOME, the arm v141LTfis and P44_STANDS added.
# It sources the frozen PREREG22 environment file unedited (p22_env.sh, md5 checked) and maps the arm onto it as run_p26.sh does:
#   v141LT     p22_env g0_off ns_c                  (bench141 block: IMULT 2.5, no height form, no threshold matching)
#   v141LTfi   P22_IMULT=1.5, p22_env v141LTfi ns_c (height form b1, b2; ING_MIN_FROM_SCORE=1; IMULT 1.5)
#   v141LTfis  as v141LTfi plus the survival switch (overlay, form fr, theta from the frozen fit file; md5 checked)
# V141_REPORT_DIR is redirected into this job. Usage: run_p49.sh ARM MODE OUT [CELLS_OR_STANDS_CSV]. Refuses to overwrite.
# No coordinates. No em dashes.
set -euo pipefail
ARM=$1; MODE=$2; OUT=$3; CELLS=${4:-}
[ ! -e "$OUT" ] || { echo "REFUSE $OUT exists"; exit 3; }
J=${P49_ROOT:-/home/aaron/jobs/v142p49}
export HOME=$J/home
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); [ "$m" = "$2" ] || { echo "FATAL md5 $1 $m != $2"; exit 4; }; }
E=$HOME/p22_env.sh; chk $E a77e811715ccf4d82f96f430db36f8c5
source $E
unset P49_SF_OVERLAY SF_FORM SF_THETA SF_TRACE P44_STANDS || true
case "$ARM" in
  v141LT)   p22_env g0_off ns_c ;;
  v141LTfi) export P22_IMULT=1.5; p22_env v141LTfi ns_c ;;
  v141LTfis) export P22_IMULT=1.5; p22_env v141LTfi ns_c
    OV=$J/scripts/sf_overlay_p49.R; chk $OV 46114af4f5d63f5763a210c23639926f
    FF=$J/fit/gyr142-p49-sffr-fit_DATA_2026-10-26.csv; chk $FF $(cut -d' ' -f1 $J/logs/fit_md5.txt)
    TH=$(awk -F, 'NR==1{for(i=1;i<=NF;i++) if($i=="estimate") c=i} NR==2{print $c}' $FF); [[ "$TH" =~ ^[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?$ ]] || { echo "FATAL fit value $TH"; exit 2; }
    export P49_SF_OVERLAY=$OV SF_FORM=fr SF_THETA=$TH ;;
  *) echo "bad ARM $ARM"; exit 2 ;;
esac
export V141_REPORT_DIR=$J/logs/counters_$ARM
export P26_MODE=$MODE P26_OUT=$OUT P26_ARM=$ARM P26_CELLS=$CELLS P26_NYR=${P26_NYR:-100} P26_SMD=${P26_SMD:-9.1}
if [ "$MODE" = slgrid ]; then export P44_STANDS=$CELLS; fi
D=$J/scripts/driver_p49.R; chk $D b6658080453ff3486cc05ea32e94fdea
cd $HOME/magplot/verify
echo "[p49] ARM=$ARM MODE=$MODE IMULT=$IMULT HTFIX_B1=${HTFIX_B1:-unset} ING=${ING_MIN_FROM_SCORE:-unset} SF_FORM=${SF_FORM:-unset} SF_THETA=${SF_THETA:-unset} SMD=$P26_SMD NYR=$P26_NYR start=$(date -Is)"
Rscript $D
echo "[p49] DONE $OUT end=$(date -Is)"
