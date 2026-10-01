#!/bin/bash
#SBATCH --job-name=p36vc
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=00:30:00
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/recs/volconv_p36/verify_20261001/%x_%j.out
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2; export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
V=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/recs/volconv_p36/verify_20261001
Rscript $V/p36_verify_c.R > $V/p36_verify_c.log 2>&1

