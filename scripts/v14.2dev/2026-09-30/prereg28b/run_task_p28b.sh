#!/bin/bash
# PREREG28b firebreather driver (copy of PREREG28 run_task_p28.sh md5 ad1fb918; arm case and taskmap only). PREREG28 driver (copy of PREREG23 run_task_p23.sh md5 0524be9c; itself a copy of PREREG19 run_task_p19.sh md5 ac029e4e): one task of work/p28_taskmap. Environment block is the bench141 v141LT array block verbatim
# (as rebased to this bundle in ~/jobs/v142p17/home/run_task_p17.sh), with the PREREG17 changes removed: no
# ING_MIN_FROM_SCORE, IMULT=2.5 (14.1 as shipped), HTFIX_B unset. The only per arm change is QC_AFAC (the QC dht.mult,
# runner line 425) or, for the smoke arms, USE_ANCHOR or QC_BREAK. Refuses to overwrite. No coordinates. No em dashes.
set -euo pipefail
T=$1; R1=$HOME; TM=$R1/work/p28b_taskmap_DATA_2026-09-30.csv
ROW=$(awk -F, -v t="$T" 'NR>1 && $1==t {print $2","$3","$4","$5","$6}' "$TM"); [ -n "$ROW" ] || { echo "task $T not in $TM"; exit 2; }
IFS=, read -r COL CHUNK SET FROM TO <<< "$ROW"
FR=$HOME/magplot/verify/gydbreg20260916/frames
export PAIRS_FILE=$FR/bench_gyr_${SET}_pairs.csv INIT_FILE=$FR/bench_gyr_${SET}_tree_init.csv T2_FILE=$FR/bench_gyr_${SET}_tree_t2.csv SITE_FILE=$FR/bench_gyr_${SET}_site_esi.csv
export CHUNK_FROM=$FROM CHUNK_TO=$TO
OUTROOT=${OUTROOT:-out}
mkdir -p $R1/$OUTROOT/$COL/$SET; export CONFIG_TAG=$R1/$OUTROOT/$COL/$SET/c$(printf %03d $CHUNK)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE ${CONFIG_TAG}_results.csv exists"; exit 3; }
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); [ "$m" = "$2" ] || { echo "FATAL md5 $1 $m != $2"; exit 4; }; }
export OMP_NUM_THREADS=1 R_DATATABLE_NUM_THREADS=1 R_LIBS_USER=/home/aaron/R/x86_64-pc-linux-gnu-library/4.5
export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export ONSET=0.55 IMULT=2.5 LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18 V132=0 INDOMAIN=1
chk $HOME/magplot/verify/p4e/model_b0b1b2.r 04a0b71da081ae98d1473391c9976896
chk $HOME/AcadianGY_13.1.r 5894df6013c701d09e7ba67ba6c2f090
export ACD_V14_BASE=$HOME/magplot/verify/p4e/model_b0b1b2.r LINKED=1 LINKED_SPRE=1 LINKED_COEF=$HOME/magplot/verify/p23/v14_coef_bundle_2026-09-08.rds
chk $LINKED_COEF 4740de88af8231677d828dec8e5b753c
export MODEL_FILE=$HOME/v14_0_4_20260917/AcadianGY_14.0.4.r; chk $MODEL_FILE 61f95d99f896e8e513930d6e33a7391a
export DBA_V1404=1 LINKED_MODE=L2 SMALLTREE=0
export V141=1 V141_FILE=$HOME/v14_1_20260923/AcadianGY_14.1.r V141_COEF=$HOME/magplot/verify/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds
export V141_RELCAP=2.9848 V141_DLO=12.7 V141_DHI=15.0 V141_REPORT_DIR=$R1/tables/counters_$COL
chk $V141_FILE 0bf27dde81240e6bdf59c9a90f0051bd; chk $V141_COEF c8f02f5841e98b93cb532b6fa9b1fc51
export LSDG_V141=1 THIN_V141=1
case "$SET" in qc_c|qc_fl) export SRC_TST=UNKNOWN ;; *) echo "FATAL set $SET not in PREREG28b"; exit 5 ;; esac
unset HTFIX_B ING_MIN_FROM_SCORE QC_AFAC_SMALL QC_AFAC_LARGE QC_AFAC_KNOT || true
case "$COL" in
  p28b_small) export QC_AFAC=0.111 QC_AFAC_SMALL=1.265 QC_AFAC_LARGE=0.111 QC_AFAC_KNOT=25 ;;
  *) echo "bad COL $COL"; exit 2 ;;
esac
RUNNER=$HOME/runner_p28_fb.R; chk $RUNNER 0a2b27421ee7b25eaab7f4591ce3af97
export TREE_OUT=$CONFIG_TAG
cd $HOME/magplot/verify
echo "[v142p28b-fb] COL=$COL task=$T set=$SET chunk=$CHUNK rows=$FROM..$TO QC_AFAC=$QC_AFAC SMALL=${QC_AFAC_SMALL:-unset} LARGE=${QC_AFAC_LARGE:-unset} KNOT=${QC_AFAC_KNOT:-unset} NB_AFAC=$NB_AFAC USE_ANCHOR=$USE_ANCHOR QC_BREAK=$QC_BREAK IMULT=$IMULT host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[v142p28b-fb] DONE ${CONFIG_TAG}_results.csv end=$(date -Is)"
