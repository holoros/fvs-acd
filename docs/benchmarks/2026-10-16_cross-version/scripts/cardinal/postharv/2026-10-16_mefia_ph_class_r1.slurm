#!/bin/bash
#SBATCH --job-name=mefiaph_cls
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=00:20:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=2 --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/acdx_20261016/postharv/logs/%x_%j.out
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
Rscript /users/PUOM0008/crsfaaron/acdx_20261016/postharv/scripts/2026-10-16_mefia_ph_class_r1.R
