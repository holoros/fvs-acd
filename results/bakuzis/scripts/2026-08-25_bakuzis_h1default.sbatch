#!/bin/bash
#SBATCH --job-name=bakuzish1
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-11
#SBATCH --time=02:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/bakuzis_h1/bakuzish1_%A_%a.out
# Bakuzis biological-consistency assessment of FVS-ACD under h1_v132_mortgate (the config adopted
# as production default 25 August 2026, commit 10ea8418). One task per benchmarked source: builds
# a long-horizon (100 year) trajectory table from real GYDB/multisrc t1 stands spanning each
# source's observed site-index range, then runs the unmodified bakuzis-assessment skill scripts
# (bakuzis_check.R, bakuzis_matrix.R) against it.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=4 R_DATATABLE_NUM_THREADS=4
cd $HOME/magplot/verify
export OUT_DIR=$HOME/magplot/verify/bakuzis_h1
export HORIZON=100
case "$SLURM_ARRAY_TASK_ID" in
  1)  export SRC=baxter ;;
  2)  export SRC=mefia_l ;;
  3)  export SRC=memat ;;
  4)  export SRC=medev ;;
  5)  export SRC=pef ;;
  6)  export SRC=ctrn ;;
  7)  export SRC=silc_l ;;
  8)  export SRC=nb ;;
  9)  export SRC=qc ;;
  10) export SRC=ns ;;
  11) export SRC=ns_long ;;
  *) echo "bad array id"; exit 2 ;;
esac
echo "[bakuzish1] task=$SLURM_ARRAY_TASK_ID SRC=$SRC HORIZON=$HORIZON"
Rscript bakuzis_h1default_traj.R
TRAJ=$OUT_DIR/${SRC}_h1default_traj.csv
if [ -f "$TRAJ" ]; then
  cd $OUT_DIR
  Rscript bakuzis_check.R "$TRAJ" > ${SRC}_h1default_bakuzis_report.txt 2>&1 || true
  Rscript bakuzis_matrix.R "$TRAJ" ${SRC}_h1default_matrix.png > ${SRC}_h1default_matrix.log 2>&1 || true
  echo "=== ${SRC} bakuzis check/matrix done ==="
else
  echo "=== ${SRC} NOT ASSESSABLE: no trajectory file produced ==="
fi
echo "=== ${SRC} TASK DONE ==="
