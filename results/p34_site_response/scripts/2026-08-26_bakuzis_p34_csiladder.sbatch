#!/bin/bash
#SBATCH --job-name=p34ladder
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-18
#SBATCH --time=03:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/bakuzis_p34/p34ladder_%A_%a.out
# Pass 34 controlled site-response experiment. The pass 32 and 33 Bakuzis site-ordering statistic
# was measured across four DIFFERENT real stands picked at site-index quantiles, which confounds the
# model's site response with stand-to-stand differences. Measured at CTRN those four stands differ
# in initial basal area with spearman(csi, BA) = -0.80 and range 78 to 100 percent softwood, one of
# them a single-species stand. This battery instead holds ONE real stand fixed per source and varies
# csi alone over 10/12/14/16/18/20.
# Tasks  1-6:  VARIANT=h1check, SDIMAX_SITE=FALSE  (production config, the decisive test)
# Tasks  7-12: VARIANT=matgate, SDIMAX_SITE=FALSE  (does the pass 33 lever change the site response)
# Tasks 13-18: VARIANT=h1check, SDIMAX_SITE=TRUE   (magnitude of the gated SDImax csi term)
#
# REVISION (first attempt, job 13974660, discarded): arms 1 and 3 share VARIANT=h1check, so both
# wrote the same intermediate <src>_h1check_p34_traj.csv before renaming to their arm tag. Running
# concurrently, one arm could rename the other's file. No output from that job is trusted. Each arm
# now writes to its own OUT_DIR, so no two tasks ever share a path and the rename is gone entirely.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=4 R_DATATABLE_NUM_THREADS=4
cd $HOME/magplot/verify
export HORIZON=100
export CSI_LADDER=10,12,14,16,18,20
SRCS=(ctrn nb qc ns memat mefia_l)
TID=$SLURM_ARRAY_TASK_ID
if [ "$TID" -le 6 ]; then
  export VARIANT=h1check; export SDIMAX_SITE=FALSE; export SRC=${SRCS[$((TID-1))]}
  ARM=h1check_sdioff
elif [ "$TID" -le 12 ]; then
  export VARIANT=matgate; export SDIMAX_SITE=FALSE; export SRC=${SRCS[$((TID-7))]}
  ARM=matgate_sdioff
else
  export VARIANT=h1check; export SDIMAX_SITE=TRUE;  export SRC=${SRCS[$((TID-13))]}
  ARM=h1check_sdion
fi
export OUT_DIR=$HOME/magplot/verify/bakuzis_p34/$ARM
mkdir -p $OUT_DIR
echo "[p34ladder] task=$TID SRC=$SRC ARM=$ARM VARIANT=$VARIANT SDIMAX_SITE=$SDIMAX_SITE ladder=$CSI_LADDER"
Rscript bakuzis_p34_traj.R
echo "=== ${SRC} ${ARM} TASK DONE ==="
