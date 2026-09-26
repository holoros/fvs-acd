#!/bin/bash
#SBATCH --job-name=v33_score
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --time=01:30:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/silc_cfi/v33_v141/logs/v33_score_%j.out
module purge
module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
cd /users/PUOM0008/crsfaaron/silc_cfi
W=v33_v141/out; F=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v141_20260923/silc_20260925/out
echo "##### IDENTITY: v33 copy with switches off against frozen 14895242 #####"
for c in v141L v141off; do a=$(md5sum $W/${c}_meas/c001_pred_t2_tree.csv | cut -d' ' -f1); b=$(md5sum $F/$c/silc_l_c/c001_pred_t2_tree.csv | cut -d' ' -f1); r=$(md5sum $W/${c}_meas/c001_results.csv | cut -d' ' -f1); s=$(md5sum $F/$c/silc_l_c/c001_results.csv | cut -d' ' -f1); echo "$c pred_t2 $a vs $b $([ $a = $b ] && echo IDENTICAL || echo DIFFER) ; results $r vs $s $([ $r = $s ] && echo IDENTICAL || echo DIFFER)"; done
Rscript v33_v141/build_unified_treelist_v33.R
export UNI_FILE=v33_v141/silc_cfi_unified_treelists_v33.csv
echo "##### PRIMARY #####"; Rscript v33_v141/value_silcspec_v33.R
echo "##### SPEC LITERAL #####"; SILC_SPEC_LITERAL=1 Rscript v33_v141/value_silcspec_v33.R
echo "##### RATES #####"; Rscript v33_v141/silc_cfi_rates_v33_SCRIPT_2026-09-26.R
echo ALLDONE
