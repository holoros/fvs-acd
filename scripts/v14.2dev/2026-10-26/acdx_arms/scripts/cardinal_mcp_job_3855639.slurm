#!/bin/bash
#SBATCH --job-name=acdxAcmp_ph
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=00:30:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=2 --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/acdx_arms_20261026/logs/%x_%j.out
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
A=/users/PUOM0008/crsfaaron/acdx_arms_20261026; md5sum $A/scripts/cmp_arms_r0.R
mkdir -p $A/cmp
for arm in p38_fit qc_rh; do
  Rscript $A/scripts/cmp_arms_r0.R /users/PUOM0008/crsfaaron/acdx_20261016/postharv/out/v141LT/mefia_ph_c $A/ph/out/$arm/mefia_ph_c ph_$arm $A/cmp/cmp_ph_${arm}_DATA_2026-10-26.csv
done

