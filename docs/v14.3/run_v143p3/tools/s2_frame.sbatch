#!/bin/bash
#SBATCH --job-name=v143p3frame
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=01:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p3/logs/frame_%j.out
# 14.3 PREREG3 (revision 1, md5 20364c4b) step 2: the joint fit frame. ROOT from V143P3_ROOT (the dry directory for the
# dry run). Script md5 checked against logs/launch_md5s.txt for the real run. No em dashes.
set -euo pipefail
R3=/users/PUOM0008/crsfaaron/v143p3
ROOT=${V143P3_ROOT:-$R3}
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
S=$R3/scripts/v143p3_fitframe.R
if [ "$ROOT" = "$R3" ]; then W=$(awk '$2=="scripts/v143p3_fitframe.R" {print $1}' $R3/logs/launch_md5s.txt | tail -1); M=$(md5sum $S | cut -d' ' -f1)
  [ -n "$W" ] && [ "$W" = "$M" ] || { echo "FATAL frame script md5 $M not the launch md5 $W"; exit 4; }; echo "md5 ok $S $M"; fi
mkdir -p $ROOT/work $ROOT/out
echo "start $(date -Is) root $ROOT"
Rscript $S $ROOT
if [ "$ROOT" = "$R3" ]; then echo "$(md5sum $ROOT/work/fitframe3_SERVERONLY.rds | cut -d' ' -f1)  work/fitframe3_SERVERONLY.rds  frame written $(date +%Y-%m-%dT%H:%M:%S%z), before any fit" >> $R3/logs/step2_md5.txt
  for f in $ROOT/out/frame3_*_DATA.csv; do echo "$(md5sum $f | cut -d' ' -f1)  out/$(basename $f)" >> $R3/logs/step2_md5.txt; done; fi
echo "end $(date -Is)"
