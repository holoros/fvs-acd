#!/bin/bash
#SBATCH --job-name=v142p17
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --time=02:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=96G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/recs/p17/logs/%x_%j.out
# PREREG17 scoring on Cardinal, for outputs that live here only: arms v141LTig_m10, _m15, _m20 and v141LTig (IMULT 1.0 to
# 2.5 under threshold matching; arrays 14922031 and 14921116), NS four plus the controls. Volume under C0, C1, C2 with the
# PREREG16 scorer (md5 019df238, copied, not edited) through a new plan CSV; structure summaries with p17_summ.R.
# Derived from recs/volconv/scripts/2026-09-27_v142_volconv_cardinal.sbatch. Frozen runs are read, not rerun. New
# directory only. No coordinates. No em dashes.
set -uo pipefail
ROOT=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916
V2=$ROOT/v142_20260925; P=$V2/recs/p17; IG=$V2/recs/ingthr
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2 OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $P
echo "019df23877abd9e1aab83831d13322dc  scripts/2026-09-27_v142_volconv_score.R" | md5sum -c - || exit 4
echo "0b604babd7cbef91afc0ded4b2687431  $HOME/hw_formrisk_split.R" | md5sum -c - || exit 4
md5sum scripts/* ~/magplot/verify/nsvb_emulator_coefs.csv ~/magplot/verify/spcd_spgrpcd.csv
PLAN=$P/plan/p17_plan_cardinal.csv
[ -e $PLAN ] && { echo "REFUSE: $PLAN exists"; exit 5; }
echo "label,set,arm,res,tree_dirs,fr,tagfr,c2,idx,v0_hard" > $PLAN
for s in ns_c ns_fl ns_long_c ns_long_fl memat_c medev_c mefia_l_c pef_c ctrn_c baxter_c qc_c; do
  case $s in ns_*|qc_*) tf=$V2/pass28/frames; c2=TRUE ;; baxter_c|ctrn_c) tf=$ROOT/frames; c2=TRUE ;; *) tf=; c2=FALSE ;; esac
  for a in v141LTig_m10 v141LTig_m15 v141LTig_m20 v141LTig; do
    echo "$s,$s,$a,$IG/results/$a/gyr_${a}_${s}_results.csv,$IG/out/$a/$s,$ROOT/frames,$tf,$c2,$ROOT/score/work/siteidx_${s}.rds,TRUE" >> $PLAN
  done
done
OUT=$P/tables; [ -e $OUT/_hardstop.txt ] && { echo "REFUSE: hard stop present"; exit 5; }
export VC_OUT=$OUT VC_PLAN=$PLAN VC_REFDIR=$HOME/magplot/verify VC_SPLIT=$HOME/hw_formrisk_split.R VC_TAG=p17
export VC_TRT=$V2/p14/out/p14_magp_treatment_DATA_2026-09-26.csv
Rscript scripts/2026-09-27_v142_volconv_score.R; rc=$?
echo "SCORE EXIT $rc"
[ $rc -eq 0 ] || exit $rc
SPLAN=$P/plan/p17_plan_cardinal_summ.csv; cp $PLAN $SPLAN
for s in ns_c ns_fl ns_long_c ns_long_fl memat_c medev_c mefia_l_c pef_c ctrn_c baxter_c qc_c; do
  echo "$s,$s,v141LT,$V2/bench141/results/v141LT/gyr_v141LT_${s}_results.csv,,,,FALSE,,FALSE" >> $SPLAN   # reference structure; its volume is read from volconv tables_r1
done
P17_OUT=$OUT P17_PLAN=$SPLAN P17_TAG=p17-cardinal Rscript scripts/2026-09-27_v142_p17_summ.R; rc=$?
echo "SUMM EXIT $rc"
if [ $rc -eq 0 ]; then for f in $OUT/*_PROVISIONAL_*.csv; do mv -n "$f" "${f/_PROVISIONAL_/_DATA_}"; done; echo P17_CARDINAL_DONE; fi
exit $rc
