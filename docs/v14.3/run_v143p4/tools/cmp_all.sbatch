#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=03:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=64G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p4/logs/%x_%j.out
# PREREG4 identity checks. Usage: sbatch --job-name=... cmp_all.sbatch <which> where which is H1a (19 sets, off against frozen
# bench141 v141LT), H1b (200 yr frame, off against frozen acdx long200 v141LT) or H2 (g0 against frozen bench141 v141LT, fold A).
# Checks the md5 of v143p4_cmp.R against logs/launch_md5s.txt first. Optional second argument: root (dry run). No em dashes.
set -euo pipefail
P=/users/PUOM0008/crsfaaron/v143p4; WH=$1; ROOT=${2:-$P}
W=$(awk '$2=="scripts/v143p4_cmp.R" {print $1}' $P/logs/launch_md5s.txt | tail -1); M=$(md5sum $P/scripts/v143p4_cmp.R | cut -d' ' -f1)
[ "$W" = "$M" ] || { echo "FATAL cmp md5"; exit 4; }
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
B141=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/bench141/out/v141LT
L200=/users/PUOM0008/crsfaaron/acdx_20261016/long200/out/v141LT
LG=$ROOT/logs
case "$WH" in
  H1a) for s in $(ls $ROOT/out/hc/off | grep -v counters); do Rscript --vanilla $P/scripts/v143p4_cmp.R $B141/$s $ROOT/out/hc/off/$s H1a_$s $LG/cmp_H1a_${s}_DATA.csv; done ;;
  H1b) Rscript --vanilla $P/scripts/v143p4_cmp.R $L200/mefia_l_c $ROOT/out/l200/off/mefia_l_c H1b $LG/cmp_H1b_mefia_l_c_DATA.csv ;;
  H2)  Rscript --vanilla $P/scripts/v143p4_cmp.R $B141/mefia_l_c $ROOT/out/hc/g0/mefia_l_c H2 $LG/cmp_H2_mefia_l_c_DATA.csv ;;
  *) echo "bad which"; exit 2 ;;
esac
echo CMP_DONE $WH
