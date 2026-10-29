#!/bin/bash
#SBATCH --job-name=v143p2_gf
#SBATCH --account=PUOM0008
#SBATCH --time=00:30:00
#SBATCH --ntasks=1 --cpus-per-task=2 --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p2/logs/s2b_gf_h3_%j.out
# 14.3 PREREG2 step 2, part B: G-F on the sealed set (A0 only) and gate H3; then the step 2 md5 record.
set -euo pipefail
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
P=/users/PUOM0008/crsfaaron/v143p2; S=$P/scripts
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); w=$(awk -v f="$2" '$2==f {print $1}' $P/logs/launch_md5s.txt | tail -1); [ "$m" = "$w" ] || { echo "FATAL md5 $1 $m != $w"; exit 4; }; echo "md5 ok $1 $m"; }
for f in v143p2_gf.R v143p2_gates.R; do chk $S/$f scripts/$f; done
Rscript $S/v143p2_gf.R $P
Rscript $S/v143p2_gates.R $P h3
cd $P
{ echo "# 14.3 PREREG2 step 2 md5 record, $(date -Is), before any fit (plan md5 b7562e8b)"
  md5sum work/fitframe_SERVERONLY.rds work/h3_sample_SERVERONLY.csv work/decomp_mefia_ph_c_SERVERONLY.rds out/frame_*_DATA.csv out/decomp_*_DATA.csv \
         sealed_SERVERONLY/* out/gf_*_DATA.csv out/gates_h3_DATA.csv logs/h6_allowlist_reads.log; } > logs/step2_md5.txt
cat logs/step2_md5.txt
echo "S2B_DONE $(date -Is)"
