#!/bin/bash
#SBATCH --job-name=acdxAb141
# ACDX ARMS COPY (2026-10-26) of /users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/bench141/scripts/2026-09-25_v142_bench141_array.sbatch: arms p38_fit and qc_rh (taskmap column 2), v141LT env verbatim plus arm exports, runner /users/PUOM0008/crsfaaron/acdx_arms_20261026/scripts/runner_arms_10y_ph.R. Diff in /users/PUOM0008/crsfaaron/acdx_arms_20261026/diffs.
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/acdx_arms_20261026/logs/%x_%A_%a.out
# Pre-registration 4, part A: 14.1 on all 19 benchmark sets (v1404/bench taskmap), arms v141off and
# v141LT, counters runner md5 300a0d61. Derived from the regional array; diff in ../diffs/.
# Large tree pre-registration 1, step 0: the 14.1 reference runs. Frozen derivative of
# v141_20260923/e6_20260925/scripts/2026-09-25_v141_E6_leg2.sbatch (the harness of run 14894607),
# generalized from ctrn_c to every row of v1404/phaseD/plan/phaseD_taskmap.csv through
# work/ref141_taskmap_DATA_2026-09-25.csv. Every environment line is that file's verbatim. Changes:
# array mapping; two arms (v141off: overlay sourced, both gates off; v141LT: both gates on);
# TST_FILE per Maine set from work/, SRC_TST=UNKNOWN outside Maine (R2.21); outputs under ref141/ only.
# Frozen 14.0.4 references in v1404/phaseD/out are NOT rerun. No em dashes.
set -euo pipefail
FR=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/frames
V=/users/PUOM0008/crsfaaron/magplot/verify
P4E=$V/p4e; P23=$V/p23
R1=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/bench141
TM=/users/PUOM0008/crsfaaron/acdx_arms_20261026/work/arms_b141_taskmap_DATA_2026-10-26.csv
ROW=$(awk -F, -v t="$SLURM_ARRAY_TASK_ID" 'NR>1 && $1==t {print $2","$3","$4","$5","$6}' "$TM")
[ -n "$ROW" ] || { echo "task $SLURM_ARRAY_TASK_ID not in $TM"; exit 2; }
IFS=, read -r ARM CHUNK SET FROM TO <<< "$ROW"; COL=v141LT
export PAIRS_FILE=$FR/bench_gyr_${SET}_pairs.csv INIT_FILE=$FR/bench_gyr_${SET}_tree_init.csv T2_FILE=$FR/bench_gyr_${SET}_tree_t2.csv
export SITE_FILE=$FR/bench_gyr_${SET}_site_esi.csv
export CHUNK_FROM=$FROM CHUNK_TO=$TO
unset SCORE_MINDBH_FIXED STAND_KEEP_FILE MGD_FILE MGD_COL MGD_UNMANAGED SRC_MANAGED V1211_MGD_PERSTAND || true
mkdir -p /users/PUOM0008/crsfaaron/acdx_arms_20261026/b141/out/$ARM/$SET
export CONFIG_TAG=/users/PUOM0008/crsfaaron/acdx_arms_20261026/b141/out/$ARM/$SET/c$(printf %03d $CHUNK)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE: ${CONFIG_TAG}_results.csv exists"; exit 3; }
chk() { local f=$1 w=$2; local m; m=$(md5sum "$f" | cut -d' ' -f1); [ "$m" = "$w" ] || { echo "FATAL md5 $f $m != $w"; exit 4; }; echo "md5 ok $f $m"; }

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
export V141_REPORT_DIR=/users/PUOM0008/crsfaaron/acdx_arms_20261026/b141/out/counters_$ARM
chk $V141_FILE 0bf27dde81240e6bdf59c9a90f0051bd
chk $V141_COEF c8f02f5841e98b93cb532b6fa9b1fc51
case "$COL" in
  v141off) export LSDG_V141=0 THIN_V141=0 ;;
  v141LT)  export LSDG_V141=1 THIN_V141=1
           case "$SET" in
             nb_c|qc_c|qc_fl|ns_c|ns_fl|ns_long_c|ns_long_fl) export SRC_TST=UNKNOWN ;;
             *) export TST_FILE=$R1/work/v142_bench141_tst_${SET}_DATA_2026-09-25.csv TST_COL=TST
                [ -s "$TST_FILE" ] || { echo "FATAL no tst file $TST_FILE"; exit 5; } ;;
           esac ;;
  *) echo "bad COL $COL"; exit 2 ;;
esac

## acdx arms (2026-10-26): v141LT environment above, verbatim, plus the frozen 14.2 arm exports (firebreather run_task_p38.sh
## 423e0162 and run_task_p45.sh ba24284a). Both act only where PROV is QC.
unset HTFIX_B ING_MIN_FROM_SCORE QC_AFAC_SMALL QC_AFAC_LARGE QC_AFAC_KNOT QC_RH_A QC_RH_B QC_RH_RFILL || true
case "$ARM" in
  p38_fit) FF=/users/PUOM0008/crsfaaron/acdx_arms_20261026/src/gyr142-p38-qcafac-fit_DATA_2026-10-01.csv; chk $FF e782957cc297e60f1f22744aea96d529; QV=$(awk -F, 'NR==2 && $1=="QC_AFAC_FIT" {print $2}' $FF); [[ "$QV" =~ ^[0-9]\.[0-9]{3}$ ]] || { echo "FATAL fit value $QV"; exit 2; }; export QC_AFAC=$QV QC_AFAC_SMALL=$QV QC_AFAC_LARGE=$QV QC_AFAC_KNOT=25 ;;
  qc_rh) FF=/users/PUOM0008/crsfaaron/acdx_arms_20261026/src/gyr142-p45-qcrh-fit_DATA_2026-10-05.csv; chk $FF 24cb959a3fc80f3c87761f9dc3737fd0; QA=$(awk -F, '$1=="a"{print $3}' $FF); QB=$(awk -F, '$1=="b"{print $3}' $FF); [[ "$QA" =~ ^-?[0-9]+\.[0-9]+$ && "$QB" =~ ^-?[0-9]+\.[0-9]+$ ]] || { echo "FATAL fit values $QA $QB"; exit 2; }; export QC_RH_A=$QA QC_RH_B=$QB QC_RH_RFILL=0.815 ;;
  *) echo "bad ARM $ARM"; exit 2 ;;
esac
echo "[acdxarms] ARM=$ARM QC_AFAC=$QC_AFAC SMALL=${QC_AFAC_SMALL:-unset} RH_A=${QC_RH_A:-unset} RH_B=${QC_RH_B:-unset}"
RUNNER=/users/PUOM0008/crsfaaron/acdx_arms_20261026/scripts/runner_arms_10y_ph.R
chk $RUNNER e85b3612d4bf9475309042436c761701
export TREE_OUT=$CONFIG_TAG
cd $V
echo "[v142ref141] COL=$COL task=$SLURM_ARRAY_TASK_ID set=$SET chunk=$CHUNK rows=$FROM..$TO LSDG=$LSDG_V141 THIN=$THIN_V141 TST_FILE=${TST_FILE:-none} SRC_TST=${SRC_TST:-unset} host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[v142ref141] DONE ${CONFIG_TAG}_results.csv end=$(date -Is)"
