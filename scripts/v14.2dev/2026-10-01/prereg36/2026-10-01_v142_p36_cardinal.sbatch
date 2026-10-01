#!/bin/bash
#SBATCH --job-name=v142p36
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --time=02:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=96G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/recs/volconv_p36/logs/%x_%j.out
# PREREG36 Part A0 and Part C on Cardinal. Scorer r2 (md5 265fc695) on the frozen PREREG16 plan volconv_plan_full_r1.csv,
# unchanged, and on a copy with QC tagfr set to pass28/qc. Same environment as the frozen sbatch (2ab975e8). Frozen runs
# and frozen tables are read, never written. New directories only; refuses to overwrite. No em dashes.
set -uo pipefail
ROOT=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916
VC=$ROOT/v142_20260925/recs/volconv; P=$ROOT/v142_20260925/recs/volconv_p36
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2 OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $P
echo "4538cb3ceff4d032009a5ef93372171e  plan/2026-10-01_v142_c2-tag-identity-r2-adoption_PREREG36.md" | md5sum -c - || exit 4
echo "265fc6950ce3f18da751da8b9fd3dbc2  scripts/2026-10-01_v142_volconv_score_r2.R" | md5sum -c - || exit 4
echo "0b604babd7cbef91afc0ded4b2687431  $HOME/hw_formrisk_split.R" | md5sum -c - || exit 4
md5sum scripts/* $VC/plan/volconv_plan_full_r1.csv $VC/tables_r1/*.csv ~/magplot/verify/nsvb_emulator_coefs.csv ~/magplot/verify/spcd_spgrpcd.csv $ROOT/v142_20260925/p14/out/p14_magp_treatment_DATA_2026-09-26.csv
cp -n $VC/plan/volconv_plan_full_r1.csv plan/p36_plan_full_r1_frozen.csv
awk -F, -v OFS=, -v q=$ROOT/v142_20260925/pass28/qc '($2=="qc_c"||$2=="qc_fl") && $3=="v141LT" {$7=q} {print}' plan/p36_plan_full_r1_frozen.csv > plan/p36_plan_full_r1_qctag.csv
diff plan/p36_plan_full_r1_frozen.csv plan/p36_plan_full_r1_qctag.csv > plan/p36_plan_qctag.diff
cat plan/p36_plan_qctag.diff
## Part A0
mkdir -p a0; P36_PLAN=plan/p36_plan_full_r1_frozen.csv,plan/p36_plan_full_r1_qctag.csv P36_OUT=a0 Rscript scripts/2026-10-01_v142_p36_a0_tagsource.R || exit 6
export VC_REFDIR=$HOME/magplot/verify VC_SPLIT=$HOME/hw_formrisk_split.R VC_TAG=volconv
export VC_TRT=$ROOT/v142_20260925/p14/out/p14_magp_treatment_DATA_2026-09-26.csv
run() { local out=$1 plan=$2
  [ -e $out ] && { echo "REFUSE $out exists"; exit 5; }; mkdir -p $out
  VC_OUT=$out VC_PLAN=$plan Rscript scripts/2026-10-01_v142_volconv_score_r2.R; rc=$?
  echo "EXIT $rc $out"; [ $rc -eq 0 ] || exit $rc
  for f in $out/*_PROVISIONAL_*.csv; do [ -e "$f" ] && mv -n "$f" "${f/_PROVISIONAL_/_DATA_}"; done; }
run $P/tables_r2 $P/plan/p36_plan_full_r1_frozen.csv
run $P/tables_r2_qctag $P/plan/p36_plan_full_r1_qctag.csv
## S0c: the seven PREREG16 tables byte identical to tables_r1
echo "S0c md5 comparison"; ok=1
for t in admission c2align c2cov gates htshare scores stands; do
  a=$(md5sum < $VC/tables_r1/gyr142-volconv-${t}_DATA_2026-09-27.csv | cut -d' ' -f1); b=$(md5sum < $P/tables_r2/gyr142-volconv-${t}_DATA_2026-09-27.csv | cut -d' ' -f1)
  [ "$a" = "$b" ] && r=SAME || { r=DIFF; ok=0; }; echo "S0c $t $a $b $r"; done
[ $ok -eq 1 ] && echo "S0c PASS" || echo "S0c FAIL"
md5sum $P/tables_r2/*.csv $P/tables_r2_qctag/*.csv a0/*.csv
echo P36_CARDINAL_DONE
