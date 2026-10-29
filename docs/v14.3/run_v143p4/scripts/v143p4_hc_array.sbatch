#!/bin/bash
#SBATCH --job-name=v143p4hc
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p4/logs/hc_%A_%a.out
# 14.3 pre-registration 4 (revision 1, md5 a15bd92a): ten year hindcast arms. COPY of the frozen bench141 launcher
# 2026-09-25_v142_bench141_array.sbatch; its environment block from "source /etc/profile.d/lmod.sh" to the V141_COEF check is
# below VERBATIM (asserted by build_v143p4.sh). Changes, and nothing else: taskmap and output root under ~/v143p4; the arm ARM
# from the taskmap with the 14.1 (v141LT) settings; V141_REPORT_DIR per arm; V141_FILE pointed at the senft overlay, which
# sources the frozen 14.1 file; SENFT switches per arm; STAND_KEEP_FILE (fold A) for the grid arms. Same runner (300a0d61).
#   off      overlay sourced, SENFT 0                         gate H1a, must equal frozen v141LT
#   g0       SENFT 1, form L, delta 0 both classes, trace     gate H2, floor domain, the delta 0 grid point
#   gL_*     SENFT 1, form L, grid delta (work/grid_coef_*)   fold A only
#   gS_*     SENFT 1, form S, grid delta                       fold A only
#   candL    SENFT 1, form L, work/senft_coef_L.csv            selected coefficients
#   candS    SENFT 1, form S, work/senft_coef_S.csv            selected coefficients
# New outputs only. No em dashes.
set -euo pipefail
FR=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/frames
V=/users/PUOM0008/crsfaaron/magplot/verify
P4E=$V/p4e; P23=$V/p23
ROOT=${V143P4_ROOT:-/users/PUOM0008/crsfaaron/v143p4}
B141=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/bench141
R1=$ROOT/out/hc
TM=${V143_TASKMAP:?set V143_TASKMAP}
ROW=$(awk -F, -v t="$SLURM_ARRAY_TASK_ID" 'NR>1 && $1==t {print $2","$3","$4","$5","$6}' "$TM")
[ -n "$ROW" ] || { echo "task $SLURM_ARRAY_TASK_ID not in $TM"; exit 2; }
IFS=, read -r ARM CHUNK SET FROM TO <<< "$ROW"; COL=v141LT
[ -n "${V143_FRAMES:-}" ] && FR=$V143_FRAMES   # dry run only
export PAIRS_FILE=$FR/bench_gyr_${SET}_pairs.csv INIT_FILE=$FR/bench_gyr_${SET}_tree_init.csv T2_FILE=$FR/bench_gyr_${SET}_tree_t2.csv
export SITE_FILE=$FR/bench_gyr_${SET}_site_esi.csv
export CHUNK_FROM=$FROM CHUNK_TO=$TO
unset SCORE_MINDBH_FIXED STAND_KEEP_FILE MGD_FILE MGD_COL MGD_UNMANAGED SRC_MANAGED V1211_MGD_PERSTAND || true
mkdir -p $R1/$ARM/$SET
export CONFIG_TAG=$R1/$ARM/$SET/c$(printf %03d $CHUNK)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE: ${CONFIG_TAG}_results.csv exists"; exit 3; }
chk() { local f=$1 w=$2; local m; m=$(md5sum "$f" | cut -d' ' -f1); [ "$m" = "$w" ] || { echo "FATAL md5 $f $m != $w"; exit 4; }; echo "md5 ok $f $m"; }
MD5F=${V143_MD5FILE:-$ROOT/logs/launch_md5s.txt}
lmd5() { awk -v f="$1" '$2==f {print $1}' $MD5F | tail -1; }

source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export ONSET=0.55 IMULT=2.5
export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export V132=0
export INDOMAIN=1
chk $P4E/model_b0b1b2.r bb51eeada62796532ce3a7212a5c6451
chk $HOME/AcadianGY_13.1.r 5894df6013c701d09e7ba67ba6c2f090
unset ACD_V14_BASE LINKED LINKED_MODE LINKED_SPRE LINKED_COEF LINKED_MORTMULT NOSDI NOCON || true
unset LINKED_FIX1 LINKED_FIX2 LINKED_FIX3 LINKED_FIX1B LINKED_FIX4 LINKED_FIX5 LINKED_DREF || true
unset SMALLTREE SMALLTREE_COEF SMALLTREE_IVREF SMALLTREE_LO SMALLTREE_HI || true
unset ACD_V141_BASE ING_V141 ING_V141_ENTRY ING_V141_KAPPA ING_V141_T ING_V141_COEF_DIR DBA_V1404 || true
unset TST_FILE TST_COL SRC_TST || true
export ACD_V14_BASE=$P4E/model_b0b1b2.r
export LINKED=1 LINKED_SPRE=1
export LINKED_COEF=$P23/v14_coef_bundle_2026-09-08.rds
chk $LINKED_COEF 4740de88af8231677d828dec8e5b753c
ENG=$HOME/v14_0_4_20260917/AcadianGY_14.0.4.r
chk $ENG 61f95d99f896e8e513930d6e33a7391a
export DBA_V1404=1
export MODEL_FILE=$ENG LINKED_MODE=L2 SMALLTREE=0

# ---- the 14.1 overlay, as E6 leg 2 ----
export V141=1 V141_FILE=$HOME/v14_1_20260923/AcadianGY_14.1.r
export V141_COEF=$V/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds
export V141_RELCAP=2.9848 V141_DLO=12.7 V141_DHI=15.0
export V141_REPORT_DIR=$R1/tables/counters_$COL
chk $V141_FILE 0bf27dde81240e6bdf59c9a90f0051bd
chk $V141_COEF c8f02f5841e98b93cb532b6fa9b1fc51

## ---- end of the verbatim block; PREREG4 arm settings follow ----
export LSDG_V141=1 THIN_V141=1
export V141_REPORT_DIR=$R1/$ARM/counters; mkdir -p $V141_REPORT_DIR
export V143_V141_BASE=$V141_FILE
OVL=$ROOT/scripts/AcadianGY_14.3dev_senft.r
W_OVL=$(lmd5 scripts/AcadianGY_14.3dev_senft.r); [ -n "$W_OVL" ] || { echo "FATAL overlay md5 not in launch_md5s.txt"; exit 4; }
chk $OVL $W_OVL
export V141_FILE=$OVL
unset SENFT SENFT_FORM SENFT_COEF SENFT_TRACE || true
EW=${V143_WORK:-$ROOT/work}; SO=${V143_SO:-$ROOT/serveronly_SERVERONLY}
case "$ARM" in
  off)   export SENFT=0 ;;
  g0)    export SENFT=1 SENFT_FORM=L SENFT_COEF=$EW/grid_coef_g0.csv STAND_KEEP_FILE=$SO/keep_foldA_SERVERONLY.csv
         export SENFT_TRACE=$R1/$ARM/$SET/trace_c$(printf %03d $CHUNK)_SERVERONLY.rds ;;
  gL_*)  export SENFT=1 SENFT_FORM=L SENFT_COEF=$EW/grid_coef_${ARM#gL_}.csv STAND_KEEP_FILE=$SO/keep_foldA_SERVERONLY.csv ;;
  gS_*)  export SENFT=1 SENFT_FORM=S SENFT_COEF=$EW/grid_coef_${ARM#gS_}.csv STAND_KEEP_FILE=$SO/keep_foldA_SERVERONLY.csv ;;
  candL) export SENFT=1 SENFT_FORM=L SENFT_COEF=$EW/senft_coef_L.csv ;;
  candS) export SENFT=1 SENFT_FORM=S SENFT_COEF=$EW/senft_coef_S.csv ;;
  D1)    export SENFT=1 SENFT_FORM=L SENFT_COEF=$EW/senft_coef_D1.csv ;;
  *) echo "FATAL unknown ARM $ARM"; exit 2 ;;
esac
if [ -n "${SENFT_COEF:-}" ]; then
  [ -s "$SENFT_COEF" ] || { echo "FATAL no coefficient file $SENFT_COEF"; exit 5; }
  W_C=$(lmd5 work/$(basename $SENFT_COEF)); [ -n "$W_C" ] || { echo "FATAL coefficient md5 not in launch_md5s.txt"; exit 4; }
  chk $SENFT_COEF $W_C
fi
if [ -n "${STAND_KEEP_FILE:-}" ]; then [ -s "$STAND_KEEP_FILE" ] || { echo "FATAL no keep file"; exit 5; }; fi
case "$SET" in
  nb_c|qc_c|qc_fl|ns_c|ns_fl|ns_long_c|ns_long_fl) export SRC_TST=UNKNOWN ;;
  *) export TST_FILE=$B141/work/v142_bench141_tst_${SET}_DATA_2026-09-25.csv TST_COL=TST
     [ -n "${V143_TST_DIR:-}" ] && export TST_FILE=$V143_TST_DIR/$(basename $TST_FILE)   # dry run only
     [ -s "$TST_FILE" ] || { echo "FATAL no tst file $TST_FILE"; exit 5; } ;;
esac
RUNNER=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/runner/scripts/2026-09-25_v142_phaseD_runner_p23_tst_counters.R
chk $RUNNER 300a0d610070f77517352c8e23f07922
export TREE_OUT=$CONFIG_TAG
cd $V
echo "[v143p4hc] ARM=$ARM task=$SLURM_ARRAY_TASK_ID set=$SET chunk=$CHUNK rows=$FROM..$TO SENFT=${SENFT:-unset} FORM=${SENFT_FORM:-none} COEF=$(basename ${SENFT_COEF:-none}) KEEP=$( [ -n "${STAND_KEEP_FILE:-}" ] && echo foldA || echo none) TST_FILE=$(basename ${TST_FILE:-none}) SRC_TST=${SRC_TST:-unset} host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[v143p4hc] DONE ${CONFIG_TAG}_results.csv end=$(date -Is)"
