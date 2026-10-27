#!/bin/bash
#SBATCH --job-name=v143p2_stress
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=08:00:00
#SBATCH --ntasks=1 --cpus-per-task=48 --mem=96G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p2/logs/s3x_stress_%x_%j.out
# 14.3 PREREG2 stress test, fit level: a full re-selection under one registered variant (exploratory; it does not change the
# verdict). The variant is passed in V143_VARIANT: bai, symcontrol, cap15, dq127, floor127, gridext.
set -euo pipefail
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2 OMP_NUM_THREADS=1
P=/users/PUOM0008/crsfaaron/v143p2; S=$P/scripts
[ -s $P/logs/selection_md5.txt ] || { echo "FATAL the primary selection record md5 is not written yet"; exit 4; }
m=$(md5sum $S/v143p2_fit.R | cut -d' ' -f1); w=$(awk '$2=="scripts/v143p2_fit.R" {print $1}' $P/logs/launch_md5s.txt | tail -1); [ "$m" = "$w" ] || { echo "FATAL md5 fit"; exit 4; }
echo "stress ${V143_VARIANT:?} start $(date -Is)"; Rscript $S/v143p2_fit.R $P $V143_VARIANT; echo "STRESS_DONE $(date -Is)"
