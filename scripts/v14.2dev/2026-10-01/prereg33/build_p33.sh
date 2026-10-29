#!/bin/bash
# PREREG33 build, step 1: new directory, PREREG28b bundle copy (home without out*, logs, tables), bundle md5 check. No em dashes.
set -euo pipefail
S=/home/aaron/jobs/v142p28b; J=/home/aaron/jobs/v142p33
for d in plan home scripts diffs logs results tables assembled out figs verify_20261001 dry; do mkdir -p $J/$d; done
cd $S/home
for f in AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p28_fb.R; do cp -p $f $J/home/; done
cp -a magplot v14_0_4_20260917 v14_1_20260923 $J/home/
mkdir -p $J/home/work
( cd $S/home && find AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p28_fb.R magplot v14_0_4_20260917 v14_1_20260923 -type f -print0 | sort -z | xargs -0 md5sum ) > $J/logs/bundle_md5_p28b_now.txt
( cd $J/home && find AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p28_fb.R magplot v14_0_4_20260917 v14_1_20260923 -type f -print0 | sort -z | xargs -0 md5sum ) > $J/logs/bundle_md5_p33.txt
cmp $J/logs/bundle_md5_p28b_now.txt $J/logs/bundle_md5_p33.txt && echo "bundle md5 identical to the PREREG28b bundle: $(wc -l < $J/logs/bundle_md5_p33.txt) files" | tee $J/logs/bundle_check.txt
cmp $S/logs/bundle_md5_p28b.txt $J/logs/bundle_md5_p33.txt && echo "and identical to the list PREREG28b recorded (logs/bundle_md5_p28b.txt)" | tee -a $J/logs/bundle_check.txt
cp -p $S/scripts/2026-09-27_v142_volconv_score.R $S/scripts/2026-09-29_v142_p23_hkey.R $J/scripts/
md5sum $J/scripts/2026-09-27_v142_volconv_score.R $J/scripts/2026-09-29_v142_p23_hkey.R $J/home/runner_p28_fb.R
echo BUILD1_DONE
