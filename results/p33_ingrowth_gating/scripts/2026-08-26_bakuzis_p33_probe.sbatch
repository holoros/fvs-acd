#!/bin/bash
#SBATCH --job-name=bakuzisp33
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-13
#SBATCH --time=02:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/bakuzis_p33/bakuzisp33_%A_%a.out
# Pass 33 probe battery: canopy/volume gating refinement of ops$use.ingrowth.release.
# Tasks 1-6:  VARIANT=noing   (ceiling probe, zero recruitment) at the six pass 32 crash sources
# Tasks 7-12: VARIANT=matgate (h2 candidate: ops$use.ingrowth.matgate, qc=12.7 cm, k=0.6)
# Task 13:    VARIANT=h1check (lever off, ctrn) -- gate G1, must be byte-identical to pass 32's
#             bakuzis_h1/ctrn_h1default_traj.csv, proving the engine edit is inert when off.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=4 R_DATATABLE_NUM_THREADS=4
cd $HOME/magplot/verify
export OUT_DIR=$HOME/magplot/verify/bakuzis_p33
export HORIZON=100
SRCS=(ctrn nb qc ns memat mefia_l)
TID=$SLURM_ARRAY_TASK_ID
if [ "$TID" -le 6 ]; then
  export VARIANT=noing;   export SRC=${SRCS[$((TID-1))]}
elif [ "$TID" -le 12 ]; then
  export VARIANT=matgate; export SRC=${SRCS[$((TID-7))]}
else
  export VARIANT=h1check; export SRC=ctrn
fi
echo "[bakuzisp33] task=$TID SRC=$SRC VARIANT=$VARIANT HORIZON=$HORIZON"
Rscript bakuzis_p33_traj.R
TRAJ=$OUT_DIR/${SRC}_${VARIANT}_traj.csv
if [ -f "$TRAJ" ]; then
  cd $OUT_DIR
  Rscript $HOME/magplot/verify/bakuzis_h1/bakuzis_check.R "$TRAJ" > ${SRC}_${VARIANT}_bakuzis_report.txt 2>&1 || true
  Rscript $HOME/magplot/verify/bakuzis_h1/bakuzis_matrix.R "$TRAJ" ${SRC}_${VARIANT}_matrix.png > ${SRC}_${VARIANT}_matrix.log 2>&1 || true
  echo "=== ${SRC} ${VARIANT} bakuzis check/matrix done ==="
else
  echo "=== ${SRC} ${VARIANT} NOT ASSESSABLE: no trajectory file produced ==="
fi
echo "=== ${SRC} ${VARIANT} TASK DONE ==="
