#!/bin/bash
# PREREG36 Part B (firebreather): r2 (265fc695, unedited) on the PREREG35 firebreather plan with QC tagfr set to the row
# index frames the frozen run used, then S0b against frozen tables_r1. New directories only. No em dashes.
set -uo pipefail
J=/home/aaron/jobs/v142p36; P=/home/aaron/jobs; X=$P/v142p19/in/xfer
cd $J
echo "4538cb3ceff4d032009a5ef93372171e  plan/2026-10-01_v142_c2-tag-identity-r2-adoption_PREREG36.md" | md5sum -c - || exit 4
echo "265fc6950ce3f18da751da8b9fd3dbc2  $P/v142p35/scripts/2026-10-01_v142_volconv_score_r2.R" | md5sum -c - || exit 4
echo "0b604babd7cbef91afc0ded4b2687431  $P/v142p28/home/hw_formrisk_split.R" | md5sum -c - || exit 4
awk -F, -v OFS=, -v q=$P/v142p14/in/frames '($2=="qc_c"||$2=="qc_fl") {$7=q} {print}' $P/v142p35/plan/p35_plan_fb_v141LT.csv > plan/p36_plan_fb_v141LT_rowidx.csv
diff $P/v142p35/plan/p35_plan_fb_v141LT.csv plan/p36_plan_fb_v141LT_rowidx.csv > diffs/p36b_plan_vs_p35.diff; cat diffs/p36b_plan_vs_p35.diff
export OMP_NUM_THREADS=4 R_DATATABLE_NUM_THREADS=4
O=$J/tables/r2_fb_rowidx; [ -e $O ] && { echo "REFUSE $O exists"; exit 5; }; mkdir -p $O
VC_OUT=$O VC_PLAN=$J/plan/p36_plan_fb_v141LT_rowidx.csv VC_TAG=volconv VC_REFDIR=$P/v142p28/home/magplot/verify VC_SPLIT=$P/v142p28/home/hw_formrisk_split.R \
  VC_TRT=$X/v142_20260925/p14/out/p14_magp_treatment_DATA_2026-09-26.csv Rscript $P/v142p35/scripts/2026-10-01_v142_volconv_score_r2.R; rc=$?
echo "EXIT $rc"; [ $rc -eq 0 ] || exit $rc
for f in $O/*_PROVISIONAL_*.csv; do [ -e "$f" ] && mv -n "$f" "${f/_PROVISIONAL_/_DATA_}"; done
Rscript scripts/2026-10-01_v142_p36_s0b.R
echo P36_B_DONE
