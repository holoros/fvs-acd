#!/bin/bash
# PREREG38 build: new directory from PREREG28b copies; taskmap, arm case, fit check, job root, arm list, scorer and log tags
# change, and the launcher and retry load tests are made strict (no start at load 12 or above). Refuses if home exists.
# No em dashes.
set -euo pipefail
S=/home/aaron/jobs/v142p28b; J=/home/aaron/jobs/v142p38
[ -e $J/home ] && { echo "REFUSE $J/home exists"; exit 3; }
mkdir -p $J/home/work $J/scripts $J/logs $J/diffs $J/fit
cd $S/home
for f in AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p28_fb.R; do cp -p $f $J/home/; done
cp -a magplot v14_0_4_20260917 v14_1_20260923 $J/home/
LIST="AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p28_fb.R magplot v14_0_4_20260917 v14_1_20260923"
( cd $S/home && find $LIST -type f -print0 | sort -z | xargs -0 md5sum ) > $J/logs/bundle_md5_p28b.txt
( cd $J/home && find $LIST -type f -print0 | sort -z | xargs -0 md5sum ) > $J/logs/bundle_md5_p38.txt
cmp $J/logs/bundle_md5_p28b.txt $J/logs/bundle_md5_p38.txt && echo "bundle md5 identical: $(wc -l < $J/logs/bundle_md5_p38.txt) files" > $J/logs/bundle_check.txt
# taskmap: PREREG28b rows 1 to 20 renamed p38_fit; rows 21 to 24 p38_one on the PREREG33 G0 subset (PREREG33 rows 21 to 24)
TM=$J/home/work/p38_taskmap_DATA_2026-10-01.csv
awk -F, 'NR==1{print; next} $1>=1 && $1<=20 {$2="p38_fit"; print}' OFS=, $S/home/work/p28b_taskmap_DATA_2026-09-30.csv > $TM
awk -F, 'NR>1 && $1>=21 && $1<=24 {$2="p38_one"; print}' OFS=, /home/aaron/jobs/v142p33/home/work/p33_taskmap_DATA_2026-10-01.csv >> $TM
seq 1 24 > $J/home/work/p38_ids.txt
# driver: arm case from a block file
cat > $J/scripts/.case_block.txt <<'EOF'
  p38_fit) FF=/home/aaron/jobs/v142p38/fit/gyr142-p38-qcafac-fit_DATA_2026-10-01.csv; chk $FF $(cut -d' ' -f1 /home/aaron/jobs/v142p38/logs/fit_md5.txt); V=$(awk -F, 'NR==2 && $1=="QC_AFAC_FIT" {print $2}' $FF); [[ "$V" =~ ^[0-9]\.[0-9]{3}$ ]] || { echo "FATAL fit value $V"; exit 2; }; export QC_AFAC=$V QC_AFAC_SMALL=$V QC_AFAC_LARGE=$V QC_AFAC_KNOT=25 ;;
  p38_one) export QC_AFAC=1.000 QC_AFAC_SMALL=1.000 QC_AFAC_LARGE=1.000 QC_AFAC_KNOT=25 ;;
EOF
awk -v bf=$J/scripts/.case_block.txt '/^  p28b_small\) export/ { while ((getline l < bf) > 0) print l; next } {print}' $S/scripts/run_task_p28b.sh | \
  sed -e 's#p28b_taskmap_DATA_2026-09-30.csv#p38_taskmap_DATA_2026-10-01.csv#' \
      -e 's#\[v142p28b-fb\]#[v142p38-fb]#g' -e 's#not in PREREG28b"#not in PREREG38"#' \
      -e 's#^\# PREREG28b firebreather driver (copy of PREREG28 run_task_p28.sh md5 ad1fb918; arm case and taskmap only).#\# PREREG38 firebreather driver (copy of PREREG28b run_task_p28b.sh md5 3969483d; taskmap, arm case with fit check, log tag only). PREREG28b driver (copy of PREREG28 run_task_p28.sh md5 ad1fb918).#' \
  > $J/scripts/run_task_p38.sh
rm $J/scripts/.case_block.txt
grep -q '^  p38_fit) ' $J/scripts/run_task_p38.sh && grep -q '^  p38_one) ' $J/scripts/run_task_p38.sh && ! grep -q p28b_small $J/scripts/run_task_p38.sh || { echo "FATAL driver build"; exit 6; }
D5=$(md5sum $J/scripts/run_task_p38.sh | cut -d' ' -f1)
sed -e 's#run_task_p28b.sh#run_task_p38.sh#g' -e 's#l<=12#l<12#' \
    -e 's#^\# PREREG28b launcher (copy of PREREG28 launch_p28.sh md5 51f3c1f7).#\# PREREG38 launcher (copy of PREREG28b launch_p28b.sh md5 cdf1bfe0; strict load test). PREREG28b launcher (copy of PREREG28 launch_p28.sh md5 51f3c1f7).#' \
    $S/scripts/launch_p28b.sh > $J/scripts/launch_p38.sh
sed -e 's#run_retry_p28b.sh#run_retry_p38.sh#g' -e 's#(\$1 > 12)#($1 >= 12)#' \
    -e 's#^\# PREREG28b (copy of PREREG28 retry_timeouts_p28.sh).#\# PREREG38 (copy of PREREG28b retry_timeouts_p28b.sh md5 c2988f6a; strict load test). PREREG28b (copy of PREREG28 retry_timeouts_p28.sh).#' \
    $S/home/retry_timeouts_p28b.sh > $J/home/retry_timeouts_p38.sh
sed -e 's#run_task_p28b.sh#run_task_p38.sh#g' -e "s#3969483d65cc4587dc72634e26c9d8d3#$D5#" -e 's#\[v142p28-retry\]#[v142p38-retry]#g' \
    -e 's#^\# PREREG28 retry driver#\# PREREG38 retry driver (copy of PREREG28b run_retry_p28b.sh md5 775256d6; driver name and md5 only). PREREG28 retry driver#' \
    $S/home/run_retry_p28b.sh > $J/home/run_retry_p38.sh
grep -q "$D5" $J/home/run_retry_p38.sh || { echo "FATAL retry md5"; exit 6; }
# scorer r2 and helper, unedited
cp -p /home/aaron/jobs/v142p35/scripts/2026-10-01_v142_volconv_score_r2.R $S/scripts/2026-09-29_v142_p23_hkey.R $J/scripts/
echo "265fc6950ce3f18da751da8b9fd3dbc2  $J/scripts/2026-10-01_v142_volconv_score_r2.R" | md5sum -c --quiet -
echo "59196106afe20e57ca1bc7b4894495f1  $J/scripts/2026-09-29_v142_p23_hkey.R" | md5sum -c --quiet -
for p in "scripts/run_task_p28b.sh scripts/run_task_p38.sh" "scripts/launch_p28b.sh scripts/launch_p38.sh" "home/retry_timeouts_p28b.sh home/retry_timeouts_p38.sh" "home/run_retry_p28b.sh home/run_retry_p38.sh" "scripts/run_score_p28b.sh scripts/run_score_p38.sh" "scripts/chain_p28b.sh scripts/chain_p38.sh" "scripts/2026-09-30_v142_p28b_assemble.R scripts/assemble_p38.R"; do
  set -- $p; [ -e $J/$2 ] && { diff $S/$1 $J/$2 > $J/diffs/$(basename $1)_to_$(basename $2).diff || true; }; done
diff $S/home/work/p28b_taskmap_DATA_2026-09-30.csv $TM > $J/diffs/taskmap.diff || true
md5sum $J/scripts/* $J/home/*.sh $J/home/runner_p28_fb.R $J/home/work/* > $J/logs/build_md5.txt
echo BUILD_DONE
