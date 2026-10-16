#!/bin/bash
#SBATCH --job-name=mefiaph_build
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=01:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=48G
#SBATCH --output=/users/PUOM0008/crsfaaron/acdx_20261016/postharv/logs/%x_%j.out
set -euo pipefail
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
cd /users/PUOM0008/crsfaaron/acdx_20261016/postharv/work
Rscript /users/PUOM0008/crsfaaron/acdx_20261016/postharv/scripts/2026-10-16_mefia_ph_frame_builder.R

