#!/bin/bash
#SBATCH --job-name=howland_decline
#SBATCH --array=1-60
#SBATCH --time=06:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=4
#SBATCH --account=PUOM0008
#SBATCH --output=/users/PUOM0008/crsfaaron/howland_decline_20261028/logs/hd_%A_%a_SERVERONLY.out
# Howland decline diagnostic for 14.3 (28 October 2026). Copy of howland_xver_array.slurm (md5 ec885ef0, never edited),
# extended to six arms on the 93 DigiSylva Howland plots, ESI 12, 15 and 18 m, 50 yr, inputs read in place from the
# frozen v141L run. Arms 1 to 3 are the reference arms for the harness gate (v141L as in howland_v141_array.slurm of
# 23 October, v141off and v131h as in howland_xver_array.slurm). Arms 4 to 6 are diagnostic arms on the v141L
# environment that change one existing runner or engine switch each and are never adopted: d141L_linkoff (LINKED=0),
# d141L_L1 (LINKED_MODE=L1), d141L_nocon (NOCON=1 with the LEV3 block unset). Runner: the HD copy of the long200 runner,
# whose only change sources the frozen hooks plus an appended flux block. Tasks 1 to 10 arm 1, 11 to 20 arm 2, and so on.
# Logs carry stand names and are therefore named _SERVERONLY. New outputs only. No em dashes.
set -euo pipefail
IN=/fs/scratch/PUOM0008/crsfaaron/HRF_v2maps/v141_check
A=/users/PUOM0008/crsfaaron/howland_decline_20261028
X=/users/PUOM0008/crsfaaron/howland_xver_20261026
V=/users/PUOM0008/crsfaaron/magplot/verify; P4E=$V/p4e; P23=$V/p23
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); [ "$m" = "$2" ] || { echo "FATAL md5 $1 $m != $2"; exit 4; }; echo "md5 ok $1"; }
inlog() { grep -q "^$(md5sum "$1" | cut -d' ' -f1) " "$2" || { echo "FATAL $1 md5 not in $2"; exit 4; }; echo "md5 recorded $1"; }
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2 OMP_NUM_THREADS=4 R_DATATABLE_NUM_THREADS=4
[ -s $A/logs/prereg_md5.txt ] || { echo "FATAL not registered"; exit 2; }
for f in howland_pairs.csv howland_tree_init.csv howland_tree_t2.csv howland_site_esi.csv; do [ -s $IN/$f ] || { echo "FATAL missing $IN/$f"; exit 2; }; inlog $IN/$f $X/logs/input_md5s.txt; done
N=$(($(wc -l < $IN/howland_pairs.csv) - 1))
ARMS=(v141L v141off v131h d141L_linkoff d141L_L1 d141L_nocon)
K=$SLURM_ARRAY_TASK_ID; AI=$(( (K-1)/10 )); C=$(( (K-1)%10 + 1 )); ARM=${ARMS[$AI]}
F=$(( (C-1)*28+1 )); T=$(( C*28 )); [ $T -le $N ] || T=$N
export PAIRS_FILE=$IN/howland_pairs.csv INIT_FILE=$IN/howland_tree_init.csv T2_FILE=$IN/howland_tree_t2.csv SITE_FILE=$IN/howland_site_esi.csv
export CHUNK_FROM=$F CHUNK_TO=$T TIMELIM=20000
unset SCORE_MINDBH_FIXED STAND_KEEP_FILE MGD_FILE MGD_COL MGD_UNMANAGED SRC_MANAGED V1211_MGD_PERSTAND || true
unset ACD_V14_BASE LINKED LINKED_MODE LINKED_SPRE LINKED_COEF LINKED_MORTMULT NOSDI NOCON B0NEW B1NEW B2NEW IMULT LEV3 LEV3_LO LEV3_HI LEV3_QMIN || true
unset V141 V141_FILE V141_COEF LSDG_V141 THIN_V141 DBA_V1404 SMALLTREE TST_FILE TST_COL SRC_TST V141_REPORT_DIR || true
mkdir -p $A/out/$ARM
if [ "$ARM" = "v131h" ]; then
  export MODEL_FILE=$HOME/AcadianGY_13.1.r; chk $MODEL_FILE 5894df6013c701d09e7ba67ba6c2f090
  export USE_HIER_ING=TRUE USE_HIER_MORT=TRUE HIER_POSTDIR=$HOME/v13_comb_post SPLIT=TRUE
  export ONSET=0.30 BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
  export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111 INDOMAIN=1 V132=0 SRC_TST=UNKNOWN
else
  export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
  export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
  export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
  export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
  export ONSET=0.55 IMULT=2.5 LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18 V132=0 INDOMAIN=1
  chk $P4E/model_b0b1b2.r bb51eeada62796532ce3a7212a5c6451; chk $HOME/AcadianGY_13.1.r 5894df6013c701d09e7ba67ba6c2f090
  export ACD_V14_BASE=$P4E/model_b0b1b2.r LINKED=1 LINKED_SPRE=1 LINKED_COEF=$P23/v14_coef_bundle_2026-09-08.rds
  chk $LINKED_COEF 4740de88af8231677d828dec8e5b753c
  ENG=$HOME/v14_0_4_20260917/AcadianGY_14.0.4.r; chk $ENG 61f95d99f896e8e513930d6e33a7391a
  export DBA_V1404=1 MODEL_FILE=$ENG LINKED_MODE=L2 SMALLTREE=0
  export V141=1 V141_FILE=$HOME/v14_1_20260923/AcadianGY_14.1.r
  export V141_COEF=$V/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds
  export V141_RELCAP=2.9848 V141_DLO=12.7 V141_DHI=15.0 V141_REPORT_DIR=$A/out/counters_$ARM
  chk $V141_FILE 0bf27dde81240e6bdf59c9a90f0051bd; chk $V141_COEF c8f02f5841e98b93cb532b6fa9b1fc51
  export LSDG_V141=0 THIN_V141=0
  case $ARM in
    v141off) : ;;
    v141L) export LSDG_V141=1 ;;
    d141L_linkoff) export LSDG_V141=1 LINKED=0 ;;
    d141L_L1) export LSDG_V141=1 LINKED_MODE=L1 ;;
    d141L_nocon) export LSDG_V141=1 NOCON=1; unset LEV3 LEV3_LO LEV3_HI LEV3_QMIN ;;
    *) echo "FATAL unknown arm $ARM"; exit 5 ;;
  esac
fi
RUNNER=$A/scripts/2026-10-28_hd_runner.R; inlog $RUNNER $A/logs/launch_md5s.txt; inlog $A/scripts/2026-10-28_hd_trajhooks_fx.R $A/logs/launch_md5s.txt
export CONFIG_TAG=$A/out/$ARM/c$(printf %02d $C)_SERVERONLY TREE_OUT=$A/out/$ARM/c$(printf %02d $C)_SERVERONLY
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE ${CONFIG_TAG}_results.csv exists"; exit 3; }
cd $V
echo "[howland_decline] ARM=$ARM task=$K chunk=$C rows=$F..$T LINKED=${LINKED:-unset} LINKED_MODE=${LINKED_MODE:-unset} LSDG_V141=${LSDG_V141:-unset} NOCON=${NOCON:-unset} LEV3=${LEV3:-unset} host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[howland_decline] DONE end=$(date -Is)"
