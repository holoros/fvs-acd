#!/bin/bash
#SBATCH --job-name=acdxAph
# ACDX ARMS COPY (2026-10-26) of /users/PUOM0008/crsfaaron/acdx_20261016/postharv/scripts/2026-10-16_mefia_ph_array.sbatch: arms p38_fit and qc_rh (taskmap column 2), v141LT env verbatim plus arm exports, runner /users/PUOM0008/crsfaaron/acdx_arms_20261026/scripts/runner_arms_10y_ph.R. Diff in /users/PUOM0008/crsfaaron/acdx_arms_20261026/diffs.
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/acdx_arms_20261026/logs/%x_%A_%a.out
# FVS-ACD post-harvest hindcast (October 16, 2026): mefia_ph_c (Maine FIA, harvest TRTCD 10 recorded at t1,
# t1 = post-harvest visit, t2 = next undisturbed visit), three arms v131h, v141LT, v141off.
# Structure copied from bench131h/scripts/cardinal_mcp_job_3929212.slurm. Arm environments are VERBATIM:
#   v131h            from bench131h/scripts/cardinal_mcp_job_3929212.slurm
#   v141LT, v141off  from v142_20260925/bench141/scripts/2026-09-25_v142_bench141_array.sbatch
# Changes: FR and R1 point to postharv; TST_FILE is the mefia_ph_c file built from FIADB TRTYR;
# V141_REPORT_DIR under postharv/out. Same counters runner (md5 300a0d61). MANAGED=1 in the pairs file,
# so the runner's MGD_USE is 1 and ops$stand.managed is TRUE. New outputs only. No em dashes.
set -euo pipefail
FR=/users/PUOM0008/crsfaaron/acdx_20261016/postharv/work
V=/users/PUOM0008/crsfaaron/magplot/verify
P4E=$V/p4e; P23=$V/p23
R1=/users/PUOM0008/crsfaaron/acdx_20261016/postharv
TM=/users/PUOM0008/crsfaaron/acdx_arms_20261026/work/arms_ph_taskmap_DATA_2026-10-26.csv
ROW=$(awk -F, -v t="$SLURM_ARRAY_TASK_ID" 'NR>1 && $1==t {print $2","$3","$4","$5","$6}' "$TM")
[ -n "$ROW" ] || { echo "task $SLURM_ARRAY_TASK_ID not in $TM"; exit 2; }
IFS=, read -r ARM CHUNK SET FROM TO <<< "$ROW"; COL=v141LT
export PAIRS_FILE=$FR/bench_gyr_${SET}_pairs.csv INIT_FILE=$FR/bench_gyr_${SET}_tree_init.csv T2_FILE=$FR/bench_gyr_${SET}_tree_t2.csv
export SITE_FILE=$FR/bench_gyr_${SET}_site_esi.csv
export CHUNK_FROM=$FROM CHUNK_TO=$TO
unset SCORE_MINDBH_FIXED STAND_KEEP_FILE MGD_FILE MGD_COL MGD_UNMANAGED SRC_MANAGED V1211_MGD_PERSTAND || true
mkdir -p /users/PUOM0008/crsfaaron/acdx_arms_20261026/ph/out/$ARM/$SET
export CONFIG_TAG=/users/PUOM0008/crsfaaron/acdx_arms_20261026/ph/out/$ARM/$SET/c$(printf %03d $CHUNK)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE: ${CONFIG_TAG}_results.csv exists"; exit 3; }
chk() { local f=$1 w=$2; local m; m=$(md5sum "$f" | cut -d' ' -f1); [ "$m" = "$w" ] || { echo "FATAL md5 $f $m != $w"; exit 4; }; echo "md5 ok $f $m"; }
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
case "$COL" in
v131h)
# ---- verbatim from bench131h/scripts/cardinal_mcp_job_3929212.slurm ----
unset ACD_V14_BASE LINKED LINKED_MODE LINKED_SPRE LINKED_COEF LINKED_MORTMULT NOSDI NOCON B0NEW B1NEW B2NEW IMULT || true
unset LEV3 LEV3_LO LEV3_HI LEV3_QMIN V141 V141_FILE V141_COEF LSDG_V141 THIN_V141 DBA_V1404 SMALLTREE TST_FILE TST_COL SRC_TST || true
export MODEL_FILE=$HOME/AcadianGY_13.1.r
chk $MODEL_FILE 5894df6013c701d09e7ba67ba6c2f090
export USE_HIER_ING=TRUE USE_HIER_MORT=TRUE HIER_POSTDIR=$HOME/v13_comb_post SPLIT=TRUE
export ONSET=0.30 BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111 INDOMAIN=1 V132=0
for f in v131r_mortB_fixef.csv v131r_ingrowth_fixef.csv; do [ -s $HIER_POSTDIR/$f ] || { echo "FATAL missing $f"; exit 6; }; done
export SRC_TST=UNKNOWN
;;
v141off|v141LT)
# ---- verbatim from v142_20260925/bench141/scripts/2026-09-25_v142_bench141_array.sbatch ----
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
export V141=1 V141_FILE=$HOME/v14_1_20260923/AcadianGY_14.1.r
export V141_COEF=$V/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds
export V141_RELCAP=2.9848 V141_DLO=12.7 V141_DHI=15.0
export V141_REPORT_DIR=/users/PUOM0008/crsfaaron/acdx_arms_20261026/ph/out/$ARM/counters
chk $V141_FILE 0bf27dde81240e6bdf59c9a90f0051bd
chk $V141_COEF c8f02f5841e98b93cb532b6fa9b1fc51
case "$COL" in
  v141off) export LSDG_V141=0 THIN_V141=0 ;;
  v141LT)  export LSDG_V141=1 THIN_V141=1
           export TST_FILE=$R1/work/mefia_ph_tst_${SET}_DATA_2026-10-16.csv TST_COL=TST
           [ -s "$TST_FILE" ] || { echo "FATAL no tst file $TST_FILE"; exit 5; } ;;
esac
;;
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
echo "[acdxph] COL=$COL task=$SLURM_ARRAY_TASK_ID set=$SET chunk=$CHUNK rows=$FROM..$TO LSDG=${LSDG_V141:-unset} THIN=${THIN_V141:-unset} TST_FILE=${TST_FILE:-none} SRC_TST=${SRC_TST:-unset} host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[acdxph] DONE ${CONFIG_TAG}_results.csv end=$(date -Is)"
