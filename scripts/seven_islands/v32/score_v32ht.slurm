#!/bin/bash
#SBATCH --job-name=v32ht_score
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --time=01:30:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/silc_cfi/v32_htdub/v32ht_score_%j.out
module purge
module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
cd /users/PUOM0008/crsfaaron/silc_cfi
Rscript v32_htdub/build_unified_treelist_v32ht.R
export UNI_FILE=v32_htdub/silc_cfi_unified_treelists_v32ht.csv
echo "##### PRIMARY #####"; Rscript v32_htdub/value_silcspec_v32ht.R
echo "##### SPEC LITERAL #####"; SILC_SPEC_LITERAL=1 Rscript v32_htdub/value_silcspec_v32ht.R
echo "##### RATES #####"; Rscript v32_htdub/silc_cfi_rates_v32ht_SCRIPT_2026-09-23.R
echo ALLDONE

