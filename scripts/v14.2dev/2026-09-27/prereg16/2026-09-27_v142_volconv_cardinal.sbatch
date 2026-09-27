#!/bin/bash
#SBATCH --job-name=v142vc
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=96G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/recs/volconv/logs/%x_%j.out
# PREREG16 scoring on Cardinal: 19 benchmark sets, arm v141LT (bench141, runner md5 300a0d61) and arm v1404_L2
# (published bench results; per tree lists exist only in phaseD v1404L2s0 for 9 sets and are admitted only if V0 holds).
# Frozen runs are read, not rerun. New directory only. MODE=smoke scores three small sets into smoke/. VC_RUN=r1 writes
# tables_r1/ after the r0 attempt stopped on a C2 tag link defect (NS pass 28 frames are reordered within stand). No em dashes.
set -uo pipefail
ROOT=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916
VC=$ROOT/v142_20260925/recs/volconv
MODE=${MODE:-full}
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2 OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $VC
md5sum scripts/*.R ~/hw_formrisk_split.R ~/magplot/verify/nsvb_emulator_coefs.csv ~/magplot/verify/spcd_spgrpcd.csv $ROOT/v142_20260925/p14/out/p14_magp_treatment_DATA_2026-09-26.csv
echo "0b604babd7cbef91afc0ded4b2687431  $HOME/hw_formrisk_split.R" | md5sum -c - || exit 4
PLAN=$VC/plan/volconv_plan_${MODE}${VC_RUN:+_$VC_RUN}.csv
mkdir -p $VC/plan
echo "label,set,arm,res,tree_dirs,fr,tagfr,c2,idx,v0_hard" > $PLAN
SETS="baxter_c silc_l_c ctrn_c ctrn_fl pef_c pef_fl mefia_l_c memat_c memat_fl medev_c medev_fl mnap_c nb_c qc_c qc_fl ns_c ns_fl ns_long_c ns_long_fl"
[ "$MODE" = smoke ] && SETS="baxter_c ctrn_fl qc_fl"
for s in $SETS; do
  lab=$s; [ "$s" = mnap_c ] && lab=mnap_tnc_frz        # PREREG15: the frozen mnap_c scores are TNC
  case $s in ns_*|qc_*) tf=$ROOT/v142_20260925/pass28/frames; c2=TRUE ;; baxter_c|ctrn_c|ctrn_fl) tf=$ROOT/frames; c2=TRUE ;; *) tf=; c2=FALSE ;; esac
  echo "$lab,$s,v141LT,$ROOT/v142_20260925/bench141/results/v141LT/gyr_v141LT_${s}_results.csv,$ROOT/v142_20260925/bench141/out/v141LT/$s,$ROOT/frames,$tf,$c2,$ROOT/score/work/siteidx_${s}.rds,TRUE" >> $PLAN
  echo "$lab,$s,v1404_L2,$ROOT/v1404/bench/results/v1404_L2/gyr_v1404_L2_${s}_results.csv,$ROOT/v1404/phaseD/out/v1404L2s0/$s,$ROOT/frames,,FALSE,$ROOT/score/work/siteidx_${s}.rds,FALSE" >> $PLAN
done
OUT=$VC/tables${VC_RUN:+_$VC_RUN}; [ "$MODE" = smoke ] && OUT=$VC/smoke${VC_RUN:+_$VC_RUN}
[ -e $OUT/_hardstop.txt ] && { echo "REFUSE: $OUT has a hard stop from an earlier attempt"; exit 5; }
export VC_OUT=$OUT VC_PLAN=$PLAN VC_REFDIR=$HOME/magplot/verify VC_SPLIT=$HOME/hw_formrisk_split.R VC_TAG=volconv
export VC_TRT=$ROOT/v142_20260925/p14/out/p14_magp_treatment_DATA_2026-09-26.csv
Rscript scripts/2026-09-27_v142_volconv_score.R
rc=$?
echo "EXIT $rc"
if [ $rc -eq 0 ] && [ "$MODE" = full ]; then
  for f in $OUT/*_PROVISIONAL_*.csv; do mv -n "$f" "${f/_PROVISIONAL_/_DATA_}"; done
  echo VC_ALL_DONE
fi
exit $rc
