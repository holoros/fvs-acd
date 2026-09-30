#!/bin/bash
# PREREG28b build: new directory from PREREG28 copies; only arm case, job root, arm list and output names change. No em dashes.
set -euo pipefail
S=/home/aaron/jobs/v142p28; J=/home/aaron/jobs/v142p28b
mkdir -p $J/home $J/scripts $J/logs $J/plan $J/diffs
cd $S/home
for f in AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p28_fb.R; do cp -p $f $J/home/; done
cp -a magplot v14_0_4_20260917 v14_1_20260923 $J/home/
mkdir -p $J/home/work
# bundle md5 check against PREREG28
( cd $S/home && find AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p28_fb.R magplot v14_0_4_20260917 v14_1_20260923 -type f -print0 | sort -z | xargs -0 md5sum ) > $J/logs/bundle_md5_p28.txt
( cd $J/home && find AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p28_fb.R magplot v14_0_4_20260917 v14_1_20260923 -type f -print0 | sort -z | xargs -0 md5sum ) > $J/logs/bundle_md5_p28b.txt
cmp $J/logs/bundle_md5_p28.txt $J/logs/bundle_md5_p28b.txt && echo "bundle md5 identical: $(wc -l < $J/logs/bundle_md5_p28b.txt) files" > $J/logs/bundle_check.txt
# taskmap: PREREG28 rows 21 to 40 renamed and renumbered
awk -F, 'NR==1{print; next} $1>=21 && $1<=40 {$1=$1-20; $2="p28b_small"; print}' OFS=, $S/home/work/p28_taskmap_DATA_2026-09-30.csv > $J/home/work/p28b_taskmap_DATA_2026-09-30.csv
seq 1 20 > $J/home/work/p28b_grid_ids.txt
# driver
sed -e 's#p28_taskmap_DATA_2026-09-30.csv#p28b_taskmap_DATA_2026-09-30.csv#' \
    -e 's#^  p28_g0) export .*#  p28b_small) export QC_AFAC=0.111 QC_AFAC_SMALL=1.265 QC_AFAC_LARGE=0.111 QC_AFAC_KNOT=25 ;;#' \
    -e '/^  p28_cand) export/d' -e '/^  p28_unset) export/d' \
    -e 's#\[v142p28-fb\]#[v142p28b-fb]#g' -e 's#not in PREREG28"#not in PREREG28b"#' \
    -e 's#^\# PREREG28 firebreather driver#\# PREREG28b firebreather driver (copy of PREREG28 run_task_p28.sh md5 ad1fb918; arm case and taskmap only). PREREG28 driver#' \
    $S/scripts/run_task_p28.sh > $J/scripts/run_task_p28b.sh
sed -e 's#run_task_p28.sh#run_task_p28b.sh#g' -e 's#^\# PREREG28 launcher#\# PREREG28b launcher (copy of PREREG28 launch_p28.sh md5 51f3c1f7). PREREG28 launcher#' $S/scripts/launch_p28.sh > $J/scripts/launch_p28b.sh
sed -e 's#run_retry_p28.sh#run_retry_p28b.sh#g' -e 's#^\# PREREG28 (copy#\# PREREG28b (copy of PREREG28 retry_timeouts_p28.sh). PREREG28 (copy#' $S/home/retry_timeouts_p28.sh > $J/home/retry_timeouts_p28b.sh
sed -e 's#v142p28/#v142p28b/#g' -e 's#run_task_p28.sh#run_task_p28b.sh#g' -e 's#p28_taskmap#p28b_taskmap#g' -e 's#\[v142p28-fb\]#[v142p28b-fb]#g' $S/home/run_retry_p28.sh > $J/home/run_retry_p28b.sh
# scorer and helper, unedited
cp -p $S/scripts/2026-09-27_v142_volconv_score.R $S/scripts/2026-09-29_v142_p23_hkey.R $J/scripts/
# score
sed -e 's#^J=/home/aaron/jobs/v142p28;#J=/home/aaron/jobs/v142p28b;#' -e 's#p28_taskmap_DATA#p28b_taskmap_DATA#' -e 's#\$1<=40#$1<=20#' \
    -e 's#^ARMS="p28_g0 p28_cand"#ARMS="p28b_small"#' -e 's#plan/p28_plan_fb#plan/p28b_plan_fb#g' -e 's#VC_TAG=p28-fb#VC_TAG=p28b-fb#g' \
    -e 's#echo P28_SCORE_DONE#echo P28B_SCORE_DONE#' -e 's#^\# PREREG28 scoring#\# PREREG28b scoring (copy of PREREG28 run_score_p28.sh md5 5a368fa6; job root, arm list, plan and tag only). PREREG28 scoring#' \
    $S/scripts/run_score_p28.sh > $J/scripts/run_score_p28b.sh
# record diffs
for p in "scripts/run_task_p28.sh scripts/run_task_p28b.sh" "scripts/launch_p28.sh scripts/launch_p28b.sh" "home/retry_timeouts_p28.sh home/retry_timeouts_p28b.sh" "home/run_retry_p28.sh home/run_retry_p28b.sh" "scripts/run_score_p28.sh scripts/run_score_p28b.sh"; do
  set -- $p; diff $S/$1 $J/$2 > $J/diffs/$(basename $2).diff || true; done
diff $S/home/work/p28_taskmap_DATA_2026-09-30.csv $J/home/work/p28b_taskmap_DATA_2026-09-30.csv > $J/diffs/taskmap.diff || true
md5sum $J/scripts/* $J/home/*.sh $J/home/runner_p28_fb.R $J/home/work/* > $J/logs/build_md5.txt
echo BUILD_DONE
