#!/bin/bash
#SBATCH --job-name=p36score
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=48G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p36/p36score_%j.out
#
# Pass 36 scoring, gating and equivalence testing. Submitted with an afterok dependency on the
# three p36 scoring arrays so it runs unattended the moment the last cell lands, rather than
# waiting on an interactive poll. The osc-cardinal connector fails on roughly half of calls, so
# anything that can be handed to the scheduler should be.
#
# Reads the result files named in the registry inside 2026-08-26_p36_score.R and writes, into
# p36/out/, the gate report, the main three-model table, the OSM common-basis panel, and the
# sessionInfo for the run. Every number in those files is derived here from the result CSVs and
# none is carried forward from a prior memo.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
P36=$HOME/magplot/verify/p36
cd $P36
Rscript $P36/2026-08-26_p36_score.R
echo "=== p36 scoring complete ==="
