#!/bin/bash
#SBATCH --job-name=p9d_crossr2
#SBATCH --account=puom0008
#SBATCH --time=00:30:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p9r2rec/p9_track_d_cross_r2.log
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.4.0
cd /users/PUOM0008/crsfaaron/magplot/verify
Rscript p9r2rec/p9_track_d_cross_r2.R
echo "P9_TRACK_D_CROSS_R2_DONE"
