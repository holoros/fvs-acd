#!/bin/bash
#SBATCH --job-name=v143p2_s2a
#SBATCH --account=PUOM0008
#SBATCH --time=03:00:00
#SBATCH --ntasks=1 --cpus-per-task=8 --mem=64G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p2/logs/s2a_%j.out
# 14.3 PREREG2 step 2, part A (real chain): fit frame, mefia_ph_c decomposition, sealed set build, launch inputs.
set -euo pipefail
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
P=/users/PUOM0008/crsfaaron/v143p2; S=$P/scripts
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); w=$(awk -v f="$2" '$2==f {print $1}' $P/logs/launch_md5s.txt | tail -1); [ "$m" = "$w" ] || { echo "FATAL md5 $1 $m != $w"; exit 4; }; echo "md5 ok $1 $m"; }
for f in v143p2_fitframe.R v143p2_decomp.R v143p2_decomp_lib.R v143p2_sealed_build.R v143p2_prep.R; do chk $S/$f scripts/$f; done
echo "=== fitframe $(date -Is)"; Rscript $S/v143p2_fitframe.R $P
echo "=== decomp $(date -Is)"; Rscript $S/v143p2_decomp.R $P
echo "=== sealed build $(date -Is)"
( export LD_LIBRARY_PATH=$HOME/.conda/envs/gdalz/lib:${LD_LIBRARY_PATH:-}; export LD_PRELOAD=$HOME/.conda/envs/gdalz/lib/libstdc++.so.6
  Rscript $S/v143p2_sealed_build.R $P/sealed_SERVERONLY )
echo "=== prep $(date -Is)"; Rscript $S/v143p2_prep.R $P harness; Rscript $S/v143p2_prep.R $P sealed A0
cd $P; for f in work/tform_coef_C0f.csv; do echo "$(md5sum $f | cut -d' ' -f1)  $f  recorded $(date -Is) by s2a" >> logs/launch_md5s.txt; done
echo "S2A_DONE $(date -Is)"
