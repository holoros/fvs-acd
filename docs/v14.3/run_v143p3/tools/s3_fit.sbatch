#!/bin/bash
#SBATCH --job-name=v143p3fit
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=08:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=48 --mem=96G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p3/logs/fit_%x_%j.out
# 14.3 PREREG3 (revision 1, md5 20364c4b) step 3: fit, CV, class gate screen, selection. Variant from V143P3_VARIANT
# (primary, p2repro, fiashare, ctrnonly, dq127, floor127, bai, rdext). ROOT from V143P3_ROOT (the dry directory with
# V143P3_DRY=1). Script md5 checked against logs/launch_md5s.txt for real runs. No em dashes.
set -euo pipefail
R3=/users/PUOM0008/crsfaaron/v143p3
ROOT=${V143P3_ROOT:-$R3}; VAR=${V143P3_VARIANT:-primary}
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2 OMP_NUM_THREADS=1 R_DATATABLE_NUM_THREADS=1
S=$R3/scripts/v143p3_fit.R
if [ "$ROOT" = "$R3" ]; then W=$(awk '$2=="scripts/v143p3_fit.R" {print $1}' $R3/logs/launch_md5s.txt | tail -1); M=$(md5sum $S | cut -d' ' -f1)
  [ -n "$W" ] && [ "$W" = "$M" ] || { echo "FATAL fit script md5 $M not the launch md5 $W"; exit 4; }; echo "md5 ok $S $M"
  if [ "$VAR" != "p2repro" ]; then grep -q "work/fitframe3_SERVERONLY.rds" $R3/logs/step2_md5.txt || { echo "FATAL no step 2 md5"; exit 4; }; fi; fi
echo "start $(date -Is) root $ROOT variant $VAR"
Rscript $S $ROOT $VAR
echo "end $(date -Is)"
