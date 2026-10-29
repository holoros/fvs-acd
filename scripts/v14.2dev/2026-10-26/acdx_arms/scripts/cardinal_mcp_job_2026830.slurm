#!/bin/bash
#SBATCH --job-name=acdxAcmp_b141
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=00:30:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=2 --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/acdx_arms_20261026/logs/%x_%j.out
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
A=/users/PUOM0008/crsfaaron/acdx_arms_20261026; md5sum $A/scripts/cmp_arms_r0.R
for arm in p38_fit qc_rh; do
  Rscript $A/scripts/cmp_arms_r0.R /users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/bench141/out/v141LT/mefia_l_c $A/b141/out/$arm/mefia_l_c b141_$arm $A/cmp/cmp_b141_${arm}_DATA_2026-10-26.csv
done

