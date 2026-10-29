#!/bin/bash
#SBATCH --job-name=bakuzisbl
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-6
#SBATCH --time=02:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/bakuzis_v132_baseline/bakuzisbl_%A_%a.out
# Pass 32: plain v13.2 baseline (no h1_v132_mortgate lever) long-horizon Bakuzis trajectories, for
# the sources where h1_v132_mortgate showed the most severe mid-rotation VOL site-ordering
# inversion (ctrn/nb/qc/ns/memat all 100/100, mefia_l 97/100). Isolates whether the crash is
# inherited from v13.2 baseline (ops$use.sdimort ONSET=0.55, present in both) or introduced by
# h1's ops$mort.dens.scale block (present ONLY here as absent, per V1211_MORTGATE default FALSE).
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=4 R_DATATABLE_NUM_THREADS=4
cd $HOME/magplot/verify
export OUT_DIR=$HOME/magplot/verify/bakuzis_v132_baseline
export HORIZON=100
case "$SLURM_ARRAY_TASK_ID" in
  1)  export SRC=ctrn ;;
  2)  export SRC=nb ;;
  3)  export SRC=qc ;;
  4)  export SRC=ns ;;
  5)  export SRC=memat ;;
  6)  export SRC=mefia_l ;;
  *) echo "bad array id"; exit 2 ;;
esac
echo "[bakuzisbl] task=$SLURM_ARRAY_TASK_ID SRC=$SRC HORIZON=$HORIZON"
Rscript bakuzis_v132baseline_traj.R
TRAJ=$OUT_DIR/${SRC}_v132baseline_traj.csv
if [ -f "$TRAJ" ]; then
  cd $OUT_DIR
  Rscript bakuzis_check.R "$TRAJ" > ${SRC}_v132baseline_bakuzis_report.txt 2>&1 || true
  Rscript bakuzis_matrix.R "$TRAJ" ${SRC}_v132baseline_matrix.png > ${SRC}_v132baseline_matrix.log 2>&1 || true
  echo "=== ${SRC} bakuzis check/matrix done ==="
else
  echo "=== ${SRC} NOT ASSESSABLE: no trajectory file produced ==="
fi
echo "=== ${SRC} TASK DONE ==="
