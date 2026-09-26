#!/bin/bash
#SBATCH --job-name=v33v141
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --time=02:30:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=8G
#SBATCH --array=1-6
#SBATCH --output=/users/PUOM0008/crsfaaron/silc_cfi/v33_v141/logs/v33_%A_%a.out
# SILC CFI benchmark v33, 26 September 2026. FVS-ACD 14.1 (and 14.0.4 as its both-gates-off arm) on the
# SILC_L frame, measured, imputed and feet-repaired starting heights. Environment is the SILC in-extent
# leg of 25 September (v141_20260923/silc_20260925/scripts/2026-09-25_v141_SILC_Lonly.sbatch, job
# 14895242) verbatim; the only change is the runner copy runner_v33_htswitch.R (parent md5 8471121e,
# one expression replaced, see its header). Tasks: 1 v141L meas, 2 v141off meas (identity against the
# frozen 14895242 outputs), 3 v141off dub, 4 v141L dub, 5 v141L ftmfix, 6 v141off ftmfix. No em dashes.
set -euo pipefail
FR=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/frames
V=/users/PUOM0008/crsfaaron/magplot/verify
P4E=$V/p4e; P23=$V/p23
SL=$V/gydbreg20260916/v141_20260923/silc_20260925
W=/users/PUOM0008/crsfaaron/silc_cfi/v33_v141
SET=silc_l_c
export PAIRS_FILE=$FR/bench_gyr_${SET}_pairs.csv INIT_FILE=$FR/bench_gyr_${SET}_tree_init.csv T2_FILE=$FR/bench_gyr_${SET}_tree_t2.csv
export SITE_FILE=$FR/bench_gyr_${SET}_site_esi.csv
export CHUNK_FROM=1 CHUNK_TO=120
unset SCORE_MINDBH_FIXED STAND_KEEP_FILE MGD_FILE MGD_COL MGD_UNMANAGED SRC_MANAGED V1211_MGD_PERSTAND || true
chk() { local f=$1 w=$2; local m; m=$(md5sum "$f" | cut -d' ' -f1); [ "$m" = "$w" ] || { echo "FATAL md5 $f $m != $w"; exit 4; }; echo "md5 ok $f $m"; }
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export ONSET=0.55 IMULT=2.5
export V132=0
export INDOMAIN=1
chk $P4E/model_b0b1b2.r bb51eeada62796532ce3a7212a5c6451
chk $HOME/AcadianGY_13.1.r 5894df6013c701d09e7ba67ba6c2f090
unset ACD_V14_BASE LINKED LINKED_MODE LINKED_SPRE LINKED_COEF LINKED_MORTMULT NOSDI NOCON || true
unset LINKED_FIX1 LINKED_FIX2 LINKED_FIX3 LINKED_FIX1B LINKED_FIX4 LINKED_FIX5 LINKED_DREF LINKED_INSTR || true
unset SMALLTREE SMALLTREE_COEF SMALLTREE_IVREF SMALLTREE_LO SMALLTREE_HI || true
unset LEV3 LEV3_LO LEV3_HI LEV3_QMIN DBA_V1404 || true
unset ACD_V141_BASE ING_V141 ING_V141_ENTRY ING_V141_KAPPA ING_V141_T ING_V141_COEF_DIR || true
unset DUB_HT FTM_FIX || true
export ACD_V14_BASE=$P4E/model_b0b1b2.r
export LINKED=1 LINKED_SPRE=1
export LINKED_COEF=$P23/v14_coef_bundle_2026-09-08.rds
chk $LINKED_COEF 4740de88af8231677d828dec8e5b753c
export LINKED_FIX1=1 LINKED_FIX2=0 LINKED_FIX3=1 LINKED_FIX4=1 LINKED_FIX5=1 LINKED_DREF=5
export SMALLTREE=0
export DBA_V1404=1
export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export LINKED_MODE=L2
export MODEL_FILE=$HOME/v14_0_4_20260917/AcadianGY_14.0.4.r
chk $MODEL_FILE 61f95d99f896e8e513930d6e33a7391a
export V141=1 V141_FILE=$HOME/v14_1_20260923/AcadianGY_14.1.r
export V141_COEF=$V/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds
export V141_RELCAP=2.9848 V141_DLO=12.7 V141_DHI=15.0
export TST_FILE=$SL/tables/gyr141-silc-tst-coverage_DATA_2026-09-25.csv TST_COL=TST
chk $V141_FILE 0bf27dde81240e6bdf59c9a90f0051bd
chk $V141_COEF c8f02f5841e98b93cb532b6fa9b1fc51
chk $TST_FILE 6657ee5415bc3c55e8bb46cb34b01422
RUNNER=$W/runner_v33_htswitch.R
chk $RUNNER fe629674786e5cd9ce03c668c17ad487
case $SLURM_ARRAY_TASK_ID in
  1) COL=v141L;   HT=meas ;;
  2) COL=v141off; HT=meas ;;
  3) COL=v141off; HT=dub;    export DUB_HT=1 ;;
  4) COL=v141L;   HT=dub;    export DUB_HT=1 ;;
  5) COL=v141L;   HT=ftmfix; export FTM_FIX=1 ;;
  6) COL=v141off; HT=ftmfix; export FTM_FIX=1 ;;
esac
case $COL in
  v141off) export LSDG_V141=0 THIN_V141=0 ;;
  v141L)   export LSDG_V141=1 THIN_V141=0 ;;
esac
mkdir -p $W/out/${COL}_${HT}
export CONFIG_TAG=$W/out/${COL}_${HT}/c001
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE: ${CONFIG_TAG}_results.csv exists"; exit 3; }
export TREE_OUT=$CONFIG_TAG V141_REPORT_DIR=$W/out/${COL}_${HT}/counters; mkdir -p $V141_REPORT_DIR
cd $V
echo "[v33] COL=$COL HT=$HT DUB_HT=${DUB_HT:-0} FTM_FIX=${FTM_FIX:-0} host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[v33] DONE ${CONFIG_TAG}_results.csv end=$(date -Is)"
