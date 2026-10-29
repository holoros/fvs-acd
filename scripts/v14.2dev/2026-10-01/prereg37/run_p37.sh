#!/bin/bash
# PREREG37 offline dht run. Usage: run_p37.sh FOLD [NMAX_STANDS]. Environment block is PREREG28 run_task_p28.sh (md5 checked
# below) from OMP_NUM_THREADS to the unset line, verbatim in content, with QC_AFAC=1 (SMALL, LARGE, KNOT unset) in place of
# the arm case, no taskmap or chunk rows (qc_c frames read whole, stands from the PREREG37 list), CONFIG_TAG and
# V141_REPORT_DIR inside ~/jobs/v142p37, TREE_OUT unset, and driver_p37.R in place of the runner. Refuses to overwrite.
set -euo pipefail
FOLD=$1; J=/home/aaron/jobs/v142p37
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); [ "$m" = "$2" ] || { echo "FATAL md5 $1 $m != $2"; exit 4; }; }
chk /home/aaron/jobs/v142p28/scripts/run_task_p28.sh "$(md5sum /home/aaron/jobs/v142p28/scripts/run_task_p28.sh | cut -d' ' -f1)"
export HOME=/home/aaron/jobs/v142p28/home; SET=qc_c
FR=$HOME/magplot/verify/gydbreg20260916/frames
export PAIRS_FILE=$FR/bench_gyr_${SET}_pairs.csv INIT_FILE=$FR/bench_gyr_${SET}_tree_init.csv T2_FILE=$FR/bench_gyr_${SET}_tree_t2.csv SITE_FILE=$FR/bench_gyr_${SET}_site_esi.csv
unset CHUNK_FROM CHUNK_TO || true
export CONFIG_TAG=$J/logs/tag_fold$FOLD
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
export V141_RELCAP=2.9848 V141_DLO=12.7 V141_DHI=15.0 V141_REPORT_DIR=$J/logs/counters_fold$FOLD
chk $V141_FILE 0bf27dde81240e6bdf59c9a90f0051bd; chk $V141_COEF c8f02f5841e98b93cb532b6fa9b1fc51
export LSDG_V141=1 THIN_V141=1
export SRC_TST=UNKNOWN
unset HTFIX_B ING_MIN_FROM_SCORE QC_AFAC_SMALL QC_AFAC_LARGE QC_AFAC_KNOT TREE_OUT || true
export QC_AFAC=1
chk $HOME/runner_p28_fb.R 0a2b27421ee7b25eaab7f4591ce3af97
D=$J/scripts/driver_p37.R; chk $D dcc32d601a6feefb4d327c821624ccd7
SL=$J/tables/gyr142-p37-stands_SERVERONLY_fold${FOLD}_2026-10-01.csv
if [ -n "${2:-}" ]; then head -n $(( $2 + 1 )) $SL > $J/logs/smoke_stands_fold$FOLD.csv; SL=$J/logs/smoke_stands_fold$FOLD.csv; OUTN=$J/logs/smoke_dhtcap_SERVERONLY_fold$FOLD.csv; else OUTN=$J/tables/gyr142-p37-dhtcap_SERVERONLY_fold${FOLD}_2026-10-01.csv; fi
export P37_STANDS=$SL P37_OUT=$OUTN P37_SPP=$J/tables/gyr142-p37-dhtspp_DATA_2026-10-01.csv
cd $HOME/magplot/verify
echo "[p37] FOLD=$FOLD QC_AFAC=$QC_AFAC IMULT=$IMULT out=$P37_OUT start=$(date -Is)"
Rscript $D
echo "[p37] DONE $P37_OUT end=$(date -Is)"
