#!/bin/bash
#SBATCH --job-name=v143grid
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=2 --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p1/logs/%x_%A_%a.out
# 14.3 pre-registration 1 (md5 7f3e67c2): the 14.1 thinned Bakuzis grid (N2), 20 cells, REGIME=thin only.
# COPY of ~/magplot/verify/gydbreg20260916/v142_20260925/bak141/scripts/2026-09-25_v142_bak141.sbatch, the launcher of
# the frozen 14.1 grid (traj_thin_v141LT). The grid's driver is the bak141 harness, so the grid cannot run from the
# mefia_ph_c launcher; its 14.1 settings are copied verbatim from that frozen grid launcher. Changes, and nothing else:
#   (1) one array task per cell for one arm given in V143_GRID_ARM (sbatch --export), REGIME=thin;
#   (2) V141_FILE is the 14.3dev overlay with THINELIG_KEY=gridcell; CONFIG is v143<ARM>;
#   (3) OUT_DIR is under ~/v143p1/out/grid/<ARM>;
#   (4) ARM=thdump runs the harness copy v143_grid_thdump.R (frozen harness plus a dump at the thinning), with 14.1
#       settings, writing the pre and post thinning tree lists to work/grid_thdump/ and stopping there (TH step).
# The frozen harness (md5 3b35a11b) is used unmodified for every arm. No em dashes.
set -euo pipefail
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=2 R_DATATABLE_NUM_THREADS=2
ROOT=/users/PUOM0008/crsfaaron/v143p1
ARM=${V143_GRID_ARM:?set V143_GRID_ARM}
CELL=$SLURM_ARRAY_TASK_ID
case "$CELL" in [0-9]|1[0-9]) ;; *) echo "FATAL the grid array must run 0-19 (harness GRID[CELL+1]; frozen cells 00 to 19)"; exit 2 ;; esac
export REGIME=thin
# ---- 14.1 grid settings, verbatim from 2026-09-25_v142_bak141.sbatch (config 2, v141LT) ----
export LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export MODEL_FILE=/users/PUOM0008/crsfaaron/v14_0_4_20260917/AcadianGY_14.0.4.r
export V141=1 V141_FILE=/users/PUOM0008/crsfaaron/v14_1_20260923/AcadianGY_14.1.r
export V141_COEF=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds
export V141_RELCAP=2.9848 V141_DLO=12.7 V141_DHI=15.0
export DBA_V1404=1
export CELL YEARS=${V143_YEARS:-160}   # V143_YEARS: dry run only
export LINKED=1 LINKED_MODE=L2
export LINKED_COEF=/users/PUOM0008/crsfaaron/magplot/verify/p23/v14_coef_bundle_2026-09-08.rds
cd /users/PUOM0008/crsfaaron/magplot/verify
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); [ "$m" = "$2" ] || { echo "FATAL md5 $1 $m != $2"; exit 9; }; }
MD5F=${V143_MD5FILE:-$ROOT/logs/launch_md5s.txt}
lmd5() { awk -v f="$1" '$2==f {print $1}' $MD5F; }
chk $MODEL_FILE 61f95d99f896e8e513930d6e33a7391a
chk $V141_FILE  0bf27dde81240e6bdf59c9a90f0051bd
chk $V141_COEF  c8f02f5841e98b93cb532b6fa9b1fc51
# ---- end of the verbatim block ----
OUTG=${V143_OUT:-$ROOT/out}/grid
if [ "$ARM" != "ref141" ] && [ "$ARM" != "refL" ]; then
export V143_V141_BASE=$V141_FILE
OVL=$ROOT/scripts/AcadianGY_14.3dev_thinelig.r; chk $OVL "$(lmd5 scripts/AcadianGY_14.3dev_thinelig.r)"
export V141_FILE=$OVL THINELIG_KEY=gridcell
fi
unset THINELIG THINELIG_FILE THINELIG_TRACE THINELIG_REPORT || true
HARN=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/bak141/scripts/2026-09-25_v142_bak141_harness.R
chk $HARN 3b35a11bff557e50ee1c1569ee1fafb6
EW=${V143_WORK:-$ROOT/work}
case "$ARM" in
  thdump) export LSDG_V141=1 THIN_V141=1 THINELIG=0 CONFIG=v143thdump
          mkdir -p $EW/grid_thdump; export V143_THDUMP=$EW/grid_thdump/cell$(printf %02d $CELL)_SERVERONLY.rds
          [ ! -e "$V143_THDUMP" ] || { echo "REFUSE exists $V143_THDUMP"; exit 3; }
          HARN=$ROOT/scripts/v143_grid_thdump.R; chk $HARN "$(lmd5 scripts/v143_grid_thdump.R)"
          export OUT_DIR=${V143_OUT:-$ROOT/out}/../tmp/grid_thdump_traj ;;
  ref141) [ -n "${V143_OUT:-}" ] || { echo "FATAL dry run only"; exit 2; }; export LSDG_V141=1 THIN_V141=1 CONFIG=v141LT OUT_DIR=$V143_OUT/frozen_standin/bak141 ;;
  refL)   [ -n "${V143_OUT:-}" ] || { echo "FATAL dry run only"; exit 2; }; export LSDG_V141=1 THIN_V141=0 CONFIG=v141L OUT_DIR=$V143_OUT/frozen_standin/bak141 ;;
  A0)     export LSDG_V141=1 THIN_V141=0 CONFIG=v143A0 OUT_DIR=$OUTG/A0 ;;
  e0off)  export LSDG_V141=1 THIN_V141=1 THINELIG=0 CONFIG=v143e0off OUT_DIR=$OUTG/e0off ;;
  *)      export LSDG_V141=1 THIN_V141=1 THINELIG=1 THINELIG_FILE=$EW/elig_${ARM}_grid_SERVERONLY.csv CONFIG=v143$ARM OUT_DIR=$OUTG/$ARM
          [ -s "$THINELIG_FILE" ] || { echo "FATAL no eligibility file $THINELIG_FILE"; exit 5; } ;;
esac
mkdir -p $OUT_DIR
case "$ARM" in thdump|ref141|refL) ;; *) export THINELIG_REPORT=$OUT_DIR/cell$(printf %02d $CELL)_thinelig_report_SERVERONLY.csv ;; esac
echo "[v143grid] ARM=$ARM CONFIG=$CONFIG CELL=$CELL L=$LSDG_V141 T=$THIN_V141 THINELIG=${THINELIG:-unset} start=$(date -Is)"
Rscript --vanilla $HARN
echo "[v143grid] DONE end=$(date -Is)"
