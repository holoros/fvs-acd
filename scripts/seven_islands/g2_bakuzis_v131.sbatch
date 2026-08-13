#!/bin/bash
#SBATCH --job-name=g2bak
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=00:30:00
#SBATCH --output=/users/PUOM0008/crsfaaron/logs/g2_bakuzis_v131_%j.out
set -uo pipefail
source /etc/profile.d/lmod.sh
module purge; module load gcc/12.3.0 R/4.4.0
export R_DATATABLE_NUM_THREADS=${SLURM_CPUS_PER_TASK:-4}
cd $HOME/magplot/verify
export MODEL_FILE=$HOME/AcadianGY_13.1.r
echo "[g2_bakuzis_v131] start $(date) MODEL_FILE=$MODEL_FILE"
export HIER_POSTDIR=${HIER_POSTDIR:-$HOME/v13_subplot}
Rscript g2_bakuzis_v131_traj.R
rc=$?
echo "[g2_bakuzis_v131] done rc=$rc $(date) -> g2_bakuzis_v131_traj.csv / g2_bakuzis_v131_relations.csv"
