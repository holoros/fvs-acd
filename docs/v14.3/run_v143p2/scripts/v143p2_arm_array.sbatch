#!/bin/bash
#SBATCH --job-name=v143p2arm
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=06:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p2/logs/arm_%A_%a.out
# 14.3 pre-registration 2 (revision 5, md5 b7562e8b): arm launcher for the Phase D frames, mefia_ph_c and the sealed set.
# COPY of ~/v143p1/scripts/v143_arm_array.sbatch (PREREG1, md5 298772e2), whose 14.1 environment block is verbatim from
# the 16 October mefia_ph_c launcher. The 14.1 block below is that block VERBATIM. Changes, and nothing else:
#   (1) frame and TST sources follow SET: mefia_ph_c from postharv/work, nhvt_ph_c (the sealed set) from
#       ~/v143p2/sealed_SERVERONLY with its TST file, the 19 Phase D sets as in PREREG1;
#   (2) V141_FILE points at the 14.3dev T form overlay (AcadianGY_14.3dev_Tform.r), which sources the frozen 14.1 file
#       named in V143_V141_BASE, except for arm v141 (the frozen 14.1 file itself, no overlay);
#   (3) the arm COL:
#         A0     LSDG 1 THIN 0, overlay off                        14.1 with T off
#         e0off  LSDG 1 THIN 1, overlay sourced but off             gate E0 (carried over), must equal frozen 14.1
#         v141   LSDG 1 THIN 1, frozen 14.1, no overlay             14.1 (sealed set, step 5a)
#         C0f    LSDG 1 THIN 1, TFORM on, candidate C0f            gate H1, must equal frozen 14.1 byte for byte
#         SEL    LSDG 1 THIN 1, TFORM on, the selected candidate, coefficients work/tform_coef_SEL.csv (KEY ALL)
#         SELN1  as SEL with leave one installation out coefficients keyed by stand (gate N1)
#         trH3   LSDG 1 THIN 1, overlay off with TFORM_TRACE on the H3 stands (STAND_KEEP_FILE)       gate H3
#         trC*   LSDG 1 THIN 1, TFORM on for candidate C*, full-data coefficients, TFORM_TRACE      gate H4
#   (4) outputs under ~/v143p2/out/arms only; md5s of the overlay and coefficient files are checked against
#       logs/launch_md5s.txt.
# Same counters runner (md5 300a0d61), unmodified. New outputs only. No em dashes.
set -euo pipefail
ROOT=${V143P2_ROOT:-/users/PUOM0008/crsfaaron/v143p2}
V=/users/PUOM0008/crsfaaron/magplot/verify
P4E=$V/p4e; P23=$V/p23
GR=$V/gydbreg20260916
B141W=$GR/v142_20260925/bench141/work
PHW=/users/PUOM0008/crsfaaron/acdx_20261016/postharv/work
SLD=${V143_SLD:-$ROOT/sealed_SERVERONLY}
TM=${V143_TASKMAP:?set V143_TASKMAP}
ROW=$(awk -F, -v t="$SLURM_ARRAY_TASK_ID" 'NR>1 && $1==t {print $2","$3","$4","$5","$6}' "$TM")
[ -n "$ROW" ] || { echo "task $SLURM_ARRAY_TASK_ID not in $TM"; exit 2; }
IFS=, read -r COL CHUNK SET FROM TO <<< "$ROW"
case "$SET" in mefia_ph_c) FR=$PHW ;; nhvt_ph_c) FR=$SLD ;; *) FR=$GR/frames ;; esac
[ -n "${V143_FRAMES:-}" ] && FR=$V143_FRAMES   # dry run only: synthetic frames
export PAIRS_FILE=$FR/bench_gyr_${SET}_pairs.csv INIT_FILE=$FR/bench_gyr_${SET}_tree_init.csv T2_FILE=$FR/bench_gyr_${SET}_tree_t2.csv
export SITE_FILE=$FR/bench_gyr_${SET}_site_esi.csv
export CHUNK_FROM=$FROM CHUNK_TO=$TO
unset SCORE_MINDBH_FIXED STAND_KEEP_FILE MGD_FILE MGD_COL MGD_UNMANAGED SRC_MANAGED V1211_MGD_PERSTAND || true
OUTR=${V143_OUT:-$ROOT/out/arms}
mkdir -p $OUTR/$COL/$SET
export CONFIG_TAG=$OUTR/$COL/$SET/c$(printf %03d $CHUNK)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE: ${CONFIG_TAG}_results.csv exists"; exit 3; }
chk() { local f=$1 w=$2; local m; m=$(md5sum "$f" | cut -d' ' -f1); [ "$m" = "$w" ] || { echo "FATAL md5 $f $m != $w"; exit 4; }; echo "md5 ok $f $m"; }
MD5F=${V143_MD5FILE:-$ROOT/logs/launch_md5s.txt}
lmd5() { awk -v f="$1" '$2==f {print $1}' $MD5F | tail -1; }
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
# ---- end of the verbatim block ----
unset TFORM TFORM_CAND TFORM_COEF TFORM_TRACE || true
EW=${V143_WORK:-$ROOT/work}
if [ "$COL" = "v141" ]; then
  export LSDG_V141=1 THIN_V141=1        # frozen 14.1, no overlay
else
  export V143_V141_BASE=$V141_FILE
  OVL=$ROOT/scripts/AcadianGY_14.3dev_Tform.r
  W_OVL=$(lmd5 scripts/AcadianGY_14.3dev_Tform.r); [ -n "$W_OVL" ] || { echo "FATAL overlay md5 not in launch_md5s.txt"; exit 4; }
  chk $OVL $W_OVL
  export V141_FILE=$OVL
  case "$COL" in
    A0)    export LSDG_V141=1 THIN_V141=0 ;;
    e0off) export LSDG_V141=1 THIN_V141=1 ;;
    C0f)   export LSDG_V141=1 THIN_V141=1 TFORM=1 TFORM_CAND=C0f TFORM_COEF=$EW/tform_coef_C0f.csv ;;
    SEL)   export LSDG_V141=1 THIN_V141=1 TFORM=1 TFORM_CAND=${V143_SELCAND:?} TFORM_COEF=$EW/tform_coef_SEL.csv ;;
    SELN1) export LSDG_V141=1 THIN_V141=1 TFORM=1 TFORM_CAND=${V143_SELCAND:?} TFORM_COEF=$EW/tform_coef_SEL_loio_SERVERONLY.csv ;;
    trH3)  export LSDG_V141=1 THIN_V141=1 STAND_KEEP_FILE=$EW/h3_stands_SERVERONLY.csv TFORM_TRACE=$OUTR/$COL/$SET/trace_c$(printf %03d $CHUNK)_SERVERONLY.rds ;;
    trC*)  CC=${COL#tr}; export LSDG_V141=1 THIN_V141=1 TFORM=1 TFORM_CAND=$CC TFORM_COEF=$EW/tform_coef_full_${CC}.csv STAND_KEEP_FILE=$EW/tr_stands_SERVERONLY.csv
           export TFORM_TRACE=$OUTR/$COL/$SET/trace_c$(printf %03d $CHUNK)_SERVERONLY.rds ;;
    *) echo "FATAL unknown COL $COL"; exit 2 ;;
  esac
  if [ -n "${TFORM_COEF:-}" ]; then
    [ -s "$TFORM_COEF" ] || { echo "FATAL no coefficient file $TFORM_COEF"; exit 5; }
    W_C=$(lmd5 work/$(basename $TFORM_COEF)); [ -n "$W_C" ] || { echo "FATAL coefficient md5 not in launch_md5s.txt"; exit 4; }
    chk $TFORM_COEF $W_C
  fi
fi
case "$SET" in
  mefia_ph_c) export TST_FILE=$PHW/mefia_ph_tst_mefia_ph_c_DATA_2026-10-16.csv TST_COL=TST ;;
  nhvt_ph_c)  export TST_FILE=$SLD/nhvt_ph_tst_SERVERONLY.csv TST_COL=TST ;;
  nb_c|qc_c|qc_fl|ns_c|ns_fl|ns_long_c|ns_long_fl) export SRC_TST=UNKNOWN ;;
  *) export TST_FILE=$B141W/v142_bench141_tst_${SET}_DATA_2026-09-25.csv TST_COL=TST ;;
esac
[ -n "${V143_TST_DIR:-}" ] && [ -n "${TST_FILE:-}" ] && export TST_FILE=$V143_TST_DIR/$(basename $TST_FILE)   # dry run only
[ -z "${TST_FILE:-}" ] || [ -s "$TST_FILE" ] || { echo "FATAL no tst file $TST_FILE"; exit 5; }
RUNNER=$GR/v142_20260925/runner/scripts/2026-09-25_v142_phaseD_runner_p23_tst_counters.R
chk $RUNNER 300a0d610070f77517352c8e23f07922
export TREE_OUT=$CONFIG_TAG
cd $V
echo "[v143p2arm] COL=$COL task=$SLURM_ARRAY_TASK_ID set=$SET chunk=$CHUNK rows=$FROM..$TO LSDG=$LSDG_V141 THIN=$THIN_V141 TFORM=${TFORM:-unset} CAND=${TFORM_CAND:-none} COEF=$(basename ${TFORM_COEF:-none}) TST_FILE=$(basename ${TST_FILE:-none}) SRC_TST=${SRC_TST:-unset} host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[v143p2arm] DONE ${CONFIG_TAG}_results.csv end=$(date -Is)"
