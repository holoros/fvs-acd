#!/bin/bash
#SBATCH --job-name=v131brms
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --mem=100G
#SBATCH --time=24:00:00
#SBATCH --output=%x_%j.out
set -e
source /etc/profile.d/lmod.sh
module purge
module load gcc/12.3.0 R/4.4.0
cd ~/v13_kickoff
export MAKEFLAGS="-j4"
echo "START $(date) host $(hostname) cpus ${SLURM_CPUS_PER_TASK}"
Rscript v131_brms_fit.R
echo "FIT_STAGE_DONE $(date)"
Rscript v131_loro.R
echo "ALL_DONE $(date)"
