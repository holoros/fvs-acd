#!/bin/bash
#SBATCH --job-name=acdx_analyze
#SBATCH --account=PUOM0008
#SBATCH --time=02:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4
#SBATCH --dependency=afterok:15578378
#SBATCH --output=/users/PUOM0008/crsfaaron/acdx_20261016/docs/acdx_analyze_%j.out
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
md5sum ~/acdx_20261016/docs/2026-10-16_acdx_analyze.R
[ ! -e /users/PUOM0008/crsfaaron/acdx_20261016/analysis ] || { echo REFUSE exists; exit 3; }
Rscript --vanilla ~/acdx_20261016/docs/2026-10-16_acdx_analyze.R /users/PUOM0008/crsfaaron/acdx_20261016/analysis 1000
cd /users/PUOM0008/crsfaaron/acdx_20261016 && tar czf acdx_analysis_DATA_2026-10-16.tgz analysis && md5sum acdx_analysis_DATA_2026-10-16.tgz

