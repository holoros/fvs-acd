#!/bin/bash
#SBATCH --job-name=v143p2grid
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=06:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=2 --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p2/logs/grid_%A_%a.out
# 14.3 pre-registration 2 (revision 5, md5 b7562e8b): the 20 cell Bakuzis grid.
# COPY of ~/v143p1/scripts/v143_grid.sbatch (PREREG1, md5 2fc4673d), whose 14.1 settings are verbatim from the frozen
# bak141 launcher. Changes, and nothing else:
#   (1) V141_FILE is the 14.3dev T form overlay (AcadianGY_14.3dev_Tform.r); arms:
#         e0off  overlay off, frozen harness, REGIME thin, 160 yr        gate E0 on the grid (equal to traj_thin_v141LT)
#         C0f    TFORM C0f, frozen harness, REGIME thin, 160 yr          gate H1 on the grid
#         gC0f   TFORM C0f, harness copy v143p2_grid_gross.R, REGIME from V143_REGIME, 200 yr (R1 reference, 14.1)
#         gSEL   TFORM the selected candidate, harness copy, REGIME from V143_REGIME, 200 yr (N2 and R1)
#   (2) OUT_DIR under ~/v143p2/out/grid/<ARM>; overlay, harness copy and coefficient md5s from logs/launch_md5s.txt.
# The frozen harness (md5 3b35a11b) is used unmodified for e0off and C0f. No em dashes.
set -euo pipefail
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=2 R_DATATABLE_NUM_THREADS=2
ROOT=${V143P2_ROOT:-/users/PUOM0008/crsfaaron/v143p2}
ARM=${V143_GRID_ARM:?set V143_GRID_ARM}
CELL=$SLURM_ARRAY_TASK_ID
case "$CELL" in [0-9]|1[0-9]) ;; *) echo "FATAL the grid array must run 0-19"; exit 2 ;; esac
# ---- 14.1 grid settings, verbatim from 2026-09-25_v142_bak141.sbatch (config 2, v141LT) ----
export LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export MODEL_FILE=/users/PUOM0008/crsfaaron/v14_0_4_20260917/AcadianGY_14.0.4.r
export V141=1 V141_FILE=/users/PUOM0008/crsfaaron/v14_1_20260923/AcadianGY_14.1.r
export V141_COEF=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds
export V141_RELCAP=2.9848 V141_DLO=12.7 V141_DHI=15.0
export DBA_V1404=1
export CELL YEARS=${V143_YEARS:-160}
export LINKED=1 LINKED_MODE=L2
export LINKED_COEF=/users/PUOM0008/crsfaaron/magplot/verify/p23/v14_coef_bundle_2026-09-08.rds
cd /users/PUOM0008/crsfaaron/magplot/verify
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); [ "$m" = "$2" ] || { echo "FATAL md5 $1 $m != $2"; exit 9; }; echo "md5 ok $1 $m"; }
MD5F=${V143_MD5FILE:-$ROOT/logs/launch_md5s.txt}
lmd5() { awk -v f="$1" '$2==f {print $1}' $MD5F | tail -1; }
chk $MODEL_FILE 61f95d99f896e8e513930d6e33a7391a
chk $V141_FILE  0bf27dde81240e6bdf59c9a90f0051bd
chk $V141_COEF  c8f02f5841e98b93cb532b6fa9b1fc51
# ---- end of the verbatim block ----
export V143_V141_BASE=$V141_FILE
OVL=$ROOT/scripts/AcadianGY_14.3dev_Tform.r; chk $OVL "$(lmd5 scripts/AcadianGY_14.3dev_Tform.r)"
export V141_FILE=$OVL
unset TFORM TFORM_CAND TFORM_COEF TFORM_TRACE || true
HARN=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/bak141/scripts/2026-09-25_v142_bak141_harness.R
chk $HARN 3b35a11bff557e50ee1c1569ee1fafb6
EW=${V143_WORK:-$ROOT/work}
OUTG=${V143_OUT:-$ROOT/out}/grid
export LSDG_V141=1 THIN_V141=1
case "$ARM" in
  e0off) export REGIME=thin CONFIG=v143p2e0off OUT_DIR=$OUTG/e0off ;;
  C0f)   export REGIME=thin CONFIG=v143p2C0f OUT_DIR=$OUTG/C0f TFORM=1 TFORM_CAND=C0f TFORM_COEF=$EW/tform_coef_C0f.csv ;;
  gC0f)  export REGIME=${V143_REGIME:?} YEARS=${V143_YEARS:-200} CONFIG=v143p2gC0f OUT_DIR=$OUTG/gC0f TFORM=1 TFORM_CAND=C0f TFORM_COEF=$EW/tform_coef_C0f.csv
         HARN=$ROOT/scripts/v143p2_grid_gross.R; chk $HARN "$(lmd5 scripts/v143p2_grid_gross.R)" ;;
  gSEL)  export REGIME=${V143_REGIME:?} YEARS=${V143_YEARS:-200} CONFIG=v143p2gSEL OUT_DIR=$OUTG/gSEL TFORM=1 TFORM_CAND=${V143_SELCAND:?} TFORM_COEF=$EW/tform_coef_SEL.csv
         HARN=$ROOT/scripts/v143p2_grid_gross.R; chk $HARN "$(lmd5 scripts/v143p2_grid_gross.R)" ;;
  *) echo "FATAL unknown ARM $ARM"; exit 2 ;;
esac
if [ -n "${TFORM_COEF:-}" ]; then chk $TFORM_COEF "$(lmd5 work/$(basename $TFORM_COEF))"; fi
mkdir -p $OUT_DIR
echo "[v143p2grid] ARM=$ARM CONFIG=$CONFIG CELL=$CELL REGIME=$REGIME YEARS=$YEARS TFORM=${TFORM:-unset} CAND=${TFORM_CAND:-none} start=$(date -Is)"
Rscript --vanilla $HARN
echo "[v143p2grid] DONE end=$(date -Is)"
