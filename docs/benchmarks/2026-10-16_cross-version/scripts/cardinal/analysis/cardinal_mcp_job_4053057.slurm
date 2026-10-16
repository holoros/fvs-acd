#!/bin/bash
#SBATCH --job-name=acdx_analyze_r1
#SBATCH --account=PUOM0008
#SBATCH --time=01:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4
#SBATCH --output=/users/PUOM0008/crsfaaron/acdx_20261016/docs/acdx_analyze_r1_%j.out
# r1: figure labels only (full forest type names, 10 yr age bins in figure 4, label fixes). Numbers must equal analysis/.
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
cd /users/PUOM0008/crsfaaron/acdx_20261016
md5sum docs/2026-10-16_acdx_analyze_r1.R
[ ! -e analysis_r1 ] || { echo REFUSE; exit 3; }
Rscript --vanilla docs/2026-10-16_acdx_analyze_r1.R /users/PUOM0008/crsfaaron/acdx_20261016/analysis_r1 1000
for f in analysis/*.csv; do b=$(basename $f); cmp -s $f analysis_r1/$b && echo "same $b" || echo "DIFF $b"; done
tar czf acdx_analysis_r1_DATA_2026-10-16.tgz analysis_r1 && md5sum acdx_analysis_r1_DATA_2026-10-16.tgz

