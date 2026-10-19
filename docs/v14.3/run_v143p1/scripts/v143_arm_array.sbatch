#!/bin/bash
#SBATCH --job-name=v143arm
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=06:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p1/logs/%x_%A_%a.out
# 14.3 pre-registration 1 (registered revision 1, md5 7f3e67c2): arm launcher for the Phase D benchmark frames.
# COPY of ~/acdx_20261016/postharv/scripts/2026-10-16_mefia_ph_array.sbatch (the 16 October mefia_ph_c launcher),
# whose v141LT block is itself verbatim from bench141. The 14.1 arm environment below is that block VERBATIM.
# Changes, and nothing else:
#   (1) the frame directory and the TST source follow SET: mefia_ph_c from postharv/work as on 16 October, the 19
#       Phase D sets from gydbreg20260916/frames with the bench141 TST file (Maine) or SRC_TST=UNKNOWN (outside
#       Maine), exactly as the bench141 array resolved them;
#   (2) V141_FILE points at the 14.3dev overlay, which sources the frozen 14.1 file named in V143_V141_BASE;
#   (3) the arm COL sets LSDG_V141, THIN_V141 and the overlay switches:
#         e0off  LSDG 1 THIN 1 THINELIG 0             gate E0, must equal frozen 14.1
#         e0b    LSDG 1 THIN 1 THINELIG 1 file ALL0    gate E0b, sets with 0 known tst, must equal frozen 14.1
#         A0     LSDG 1 THIN 0                         14.1 with T off
#         Apv A1 A2 A3 and stress arm names  LSDG 1 THIN 1 THINELIG 1 file elig_<COL>_<SET>
#         trA3   as A3 with THINELIG_TRACE on the TR stands (STAND_KEEP_FILE), gate TR
#         ref141 refL2  dry run only (refused unless V143_OUT is set): plain 14.1 and 14.0.4 L2 on synthetic stands
#   (4) outputs under ~/v143p1/out only; the md5 of the overlay is checked against logs/launch_md5s.txt (this
#       launcher's own md5 is recorded there before the chain starts).
# Same counters runner (md5 300a0d61), unmodified. New outputs only. No em dashes.
set -euo pipefail
ROOT=/users/PUOM0008/crsfaaron/v143p1
V=/users/PUOM0008/crsfaaron/magplot/verify
P4E=$V/p4e; P23=$V/p23
GR=$V/gydbreg20260916
B141W=$GR/v142_20260925/bench141/work
PHW=/users/PUOM0008/crsfaaron/acdx_20261016/postharv/work
TM=${V143_TASKMAP:-$ROOT/work/v143_taskmap_DATA.csv}
ROW=$(awk -F, -v t="$SLURM_ARRAY_TASK_ID" 'NR>1 && $1==t {print $2","$3","$4","$5","$6}' "$TM")
[ -n "$ROW" ] || { echo "task $SLURM_ARRAY_TASK_ID not in $TM"; exit 2; }
IFS=, read -r COL CHUNK SET FROM TO <<< "$ROW"
if [ "$SET" = "mefia_ph_c" ]; then FR=$PHW; else FR=$GR/frames; fi
[ -n "${V143_FRAMES:-}" ] && FR=$V143_FRAMES   # dry run only: synthetic frames
export PAIRS_FILE=$FR/bench_gyr_${SET}_pairs.csv INIT_FILE=$FR/bench_gyr_${SET}_tree_init.csv T2_FILE=$FR/bench_gyr_${SET}_tree_t2.csv
export SITE_FILE=$FR/bench_gyr_${SET}_site_esi.csv
export CHUNK_FROM=$FROM CHUNK_TO=$TO
unset SCORE_MINDBH_FIXED STAND_KEEP_FILE MGD_FILE MGD_COL MGD_UNMANAGED SRC_MANAGED V1211_MGD_PERSTAND || true
OUTR=${V143_OUT:-$ROOT/out}
mkdir -p $OUTR/$COL/$SET
export CONFIG_TAG=$OUTR/$COL/$SET/c$(printf %03d $CHUNK)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE: ${CONFIG_TAG}_results.csv exists"; exit 3; }
chk() { local f=$1 w=$2; local m; m=$(md5sum "$f" | cut -d' ' -f1); [ "$m" = "$w" ] || { echo "FATAL md5 $f $m != $w"; exit 4; }; echo "md5 ok $f $m"; }
MD5F=${V143_MD5FILE:-$ROOT/logs/launch_md5s.txt}   # dry run: a dry run md5 file
lmd5() { awk -v f="$1" '$2==f {print $1}' $MD5F; }
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
# ---- 14.1, verbatim from 2026-10-16_mefia_ph_array.sbatch (v141off|v141LT block) ----
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
export V141_REPORT_DIR=$OUTR/$COL/counters
chk $V141_FILE 0bf27dde81240e6bdf59c9a90f0051bd
chk $V141_COEF c8f02f5841e98b93cb532b6fa9b1fc51
# ---- end of the verbatim block; the 14.3dev overlay is loaded in place of the 14.1 file, which it sources ----
if [ "$COL" = "ref141" ] || [ "$COL" = "refL2" ]; then
  # dry run only: plain 14.1 (ref141) and 14.0.4 L2 (refL2) stand in for the frozen references on synthetic stands
  [ -n "${V143_OUT:-}" ] || { echo "FATAL reference arms are dry run only"; exit 2; }
  case "$COL" in ref141) export LSDG_V141=1 THIN_V141=1 ;; refL2) export LSDG_V141=0 THIN_V141=0 ;; esac
else
export V143_V141_BASE=$V141_FILE
OVL=$ROOT/scripts/AcadianGY_14.3dev_thinelig.r
W_OVL=$(lmd5 scripts/AcadianGY_14.3dev_thinelig.r); [ -n "$W_OVL" ] || { echo "FATAL overlay md5 not in launch_md5s.txt"; exit 4; }
chk $OVL $W_OVL
export V141_FILE=$OVL
unset THINELIG THINELIG_FILE THINELIG_KEY THINELIG_TRACE THINELIG_REPORT || true
EW=${V143_WORK:-$ROOT/work}
case "$COL" in
  A0)    export LSDG_V141=1 THIN_V141=0 ;;
  e0off) export LSDG_V141=1 THIN_V141=1 THINELIG=0 ;;
  e0b)   export LSDG_V141=1 THIN_V141=1 THINELIG=1 THINELIG_FILE=$EW/elig_ALL0_${SET}_SERVERONLY.csv ;;
  trA3)  export LSDG_V141=1 THIN_V141=1 THINELIG=1 THINELIG_FILE=$EW/elig_A3_${SET}_SERVERONLY.csv
         export STAND_KEEP_FILE=$EW/tr_stands_SERVERONLY.csv THINELIG_TRACE=$OUTR/$COL/$SET/trace_c$(printf %03d $CHUNK)_SERVERONLY.rds ;;
  *)     export LSDG_V141=1 THIN_V141=1 THINELIG=1 THINELIG_FILE=$EW/elig_${COL}_${SET}_SERVERONLY.csv ;;
esac
[ -z "${THINELIG_FILE:-}" ] || [ -s "$THINELIG_FILE" ] || { echo "FATAL no eligibility file $THINELIG_FILE"; exit 5; }
export THINELIG_REPORT=$OUTR/$COL/$SET/c$(printf %03d $CHUNK)_thinelig_report_SERVERONLY.csv
fi
if [ "$THIN_V141" = "1" ] || [ "$COL" = "A0" ]; then
  case "$SET" in
    mefia_ph_c) export TST_FILE=$PHW/mefia_ph_tst_mefia_ph_c_DATA_2026-10-16.csv TST_COL=TST ;;
    nb_c|qc_c|qc_fl|ns_c|ns_fl|ns_long_c|ns_long_fl) export SRC_TST=UNKNOWN ;;
    *) export TST_FILE=$B141W/v142_bench141_tst_${SET}_DATA_2026-09-25.csv TST_COL=TST ;;
  esac
  [ -n "${V143_TST_DIR:-}" ] && [ -n "${TST_FILE:-}" ] && export TST_FILE=$V143_TST_DIR/$(basename $TST_FILE)   # dry run only
  [ -z "${TST_FILE:-}" ] || [ -s "$TST_FILE" ] || { echo "FATAL no tst file $TST_FILE"; exit 5; }
fi
RUNNER=$GR/v142_20260925/runner/scripts/2026-09-25_v142_phaseD_runner_p23_tst_counters.R
chk $RUNNER 300a0d610070f77517352c8e23f07922
export TREE_OUT=$CONFIG_TAG
cd $V
echo "[v143arm] COL=$COL task=$SLURM_ARRAY_TASK_ID set=$SET chunk=$CHUNK rows=$FROM..$TO LSDG=$LSDG_V141 THIN=$THIN_V141 THINELIG=${THINELIG:-unset} FILE=$(basename ${THINELIG_FILE:-none}) TST_FILE=$(basename ${TST_FILE:-none}) SRC_TST=${SRC_TST:-unset} host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[v143arm] DONE ${CONFIG_TAG}_results.csv end=$(date -Is)"
