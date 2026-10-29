#!/bin/bash
#SBATCH --job-name=v143p4e0
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=00:40:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=2 --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p4/explore/e0_%j.out
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
Rscript --vanilla /users/PUOM0008/crsfaaron/v143p4/explore/e0_branch_explore.R
