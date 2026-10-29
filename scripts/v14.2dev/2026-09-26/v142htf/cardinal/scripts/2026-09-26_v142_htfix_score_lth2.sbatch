#!/bin/bash
#SBATCH --job-name=v142htS2
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --time=06:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=200G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/recs/htfix/logs/%x_%j.out
# PREREG11 scoring, gated arm v141LTh (firebreather outputs, slim transfer md5 75d69c17). Cardinal named for scoring by Aaron.
set -uo pipefail
H=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/recs/htfix
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2 OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $H/fbout; echo "75d69c172c00755285f5d4ee6a532745  v141LTh_slim_2026-09-26.tgz" | md5sum -c - || exit 4

# assembly and H1, H2 done in job 14926285

cd $H/score; md5sum R/*.R; Rscript R/ht_score_run_lth_fb.R
echo SCORE_LTH_DONE
