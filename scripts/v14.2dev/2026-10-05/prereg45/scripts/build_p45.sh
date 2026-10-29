#!/bin/bash
# PREREG45 build. (1) Benchmark bundle: PREREG38 bundle files copied, md5 list must equal PREREG38's; runner_p45_fb.R is
# runner_p28_fb.R (0a2b2742) with the htfx line replaced by parts/htfx_rh_block.R (asserted once). (2) Long run driver:
# driver_p45.R is driver_p44.R (7d5da479) with the same single replacement. (3) Task, launcher, retry and score wrappers
# are PREREG38 copies with job root, taskmap, arm case, runner and md5 and tags changed; run_p45.sh is run_p44.sh with job
# root, driver and md5 and arm case changed. Refuses if home exists. No em dashes.
set -euo pipefail
S38=/home/aaron/jobs/v142p38; S44=/home/aaron/jobs/v142p44; J=/home/aaron/jobs/v142p45
[ -e $J/home ] && { echo "REFUSE $J/home exists"; exit 3; }
mkdir -p $J/home/work $J/diffs
LIST="AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p28_fb.R magplot v14_0_4_20260917 v14_1_20260923"
cd $S38/home; for f in AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p28_fb.R; do cp -p $f $J/home/; done
cp -a magplot v14_0_4_20260917 v14_1_20260923 $J/home/
( cd $J/home && find $LIST -type f -print0 | sort -z | xargs -0 md5sum ) > $J/logs/bundle_md5_p45.txt
cmp $S38/logs/bundle_md5_p38.txt $J/logs/bundle_md5_p45.txt && echo "bundle md5 identical to PREREG38: $(wc -l < $J/logs/bundle_md5_p45.txt) files" > $J/logs/bundle_check.txt
python3 - <<'PY'
import re
blk=open("/home/aaron/jobs/v142p45/scripts/parts/htfx_rh_block.R").read().rstrip("\n")
old='htfx <- function(x, p) { if (!is.finite(HTFIX_B) || p$PROV != "NS") return(x); x$dht.mult <- exp(-HTFIX_B * pmax(0, x$dbh - 12.7)); x }'
for src,dst in [("/home/aaron/jobs/v142p45/home/runner_p28_fb.R","/home/aaron/jobs/v142p45/home/runner_p45_fb.R"),("/home/aaron/jobs/v142p44/scripts/driver_p44.R","/home/aaron/jobs/v142p45/scripts/driver_p45.R")]:
    t=open(src).read(); n=t.count(old+"\n"); assert n==1,(src,n); open(dst,"w").write(t.replace(old+"\n",blk+"\n")); print("edited",dst)
PY
diff $J/home/runner_p28_fb.R $J/home/runner_p45_fb.R > $J/diffs/runner_p28_fb.R_to_runner_p45_fb.R.diff || true
diff $S44/scripts/driver_p44.R $J/scripts/driver_p45.R > $J/diffs/driver_p44.R_to_driver_p45.R.diff || true
RM=$(md5sum $J/home/runner_p45_fb.R | cut -d' ' -f1); DM=$(md5sum $J/scripts/driver_p45.R | cut -d' ' -f1)
TM=$J/home/work/p45_taskmap_DATA_2026-10-05.csv
awk -F, 'NR==1{print; next} $1>=1 && $1<=20 {$2="qc_rh"; print} $1>=21 && $1<=24 {$2="qc_rh0"; print}' OFS=, $S38/home/work/p38_taskmap_DATA_2026-10-01.csv > $TM
seq 1 24 > $J/home/work/p45_ids.txt
cat > $J/scripts/.case.txt <<'CASE'
  qc_rh) FF=/home/aaron/jobs/v142p45/fit/gyr142-p45-qcrh-fit_DATA_2026-10-05.csv; chk $FF $(cut -d' ' -f1 /home/aaron/jobs/v142p45/logs/fit_md5.txt); A=$(awk -F, '$1=="a"{print $3}' $FF); Bv=$(awk -F, '$1=="b"{print $3}' $FF); [[ "$A" =~ ^-?[0-9]+\.[0-9]+$ && "$Bv" =~ ^-?[0-9]+\.[0-9]+$ ]] || { echo "FATAL fit values $A $Bv"; exit 2; }; export QC_RH_A=$A QC_RH_B=$Bv QC_RH_RFILL=0.815 ;;
  qc_rh0) export QC_RH_A=0 QC_RH_B=0 QC_RH_RFILL=0.815 QC_AFAC=1.000 ;;
CASE
awk -v bf=$J/scripts/.case.txt '/^  p38_fit\) FF=/ { while ((getline l < bf) > 0) print l; next } /^  p38_one\) export/ {next} {print}' $S38/scripts/run_task_p38.sh | \
  sed -e 's#p38_taskmap_DATA_2026-10-01.csv#p45_taskmap_DATA_2026-10-05.csv#' -e 's#\[v142p38-fb\]#[v142p45-fb]#g' -e 's#not in PREREG38"#not in PREREG45"#' \
      -e 's#unset HTFIX_B ING_MIN_FROM_SCORE QC_AFAC_SMALL QC_AFAC_LARGE QC_AFAC_KNOT || true#unset HTFIX_B ING_MIN_FROM_SCORE QC_AFAC_SMALL QC_AFAC_LARGE QC_AFAC_KNOT QC_RH_A QC_RH_B QC_RH_RFILL || true#' \
      -e "s#RUNNER=\$HOME/runner_p28_fb.R; chk \$RUNNER 0a2b27421ee7b25eaab7f4591ce3af97#RUNNER=\$HOME/runner_p45_fb.R; chk \$RUNNER $RM#" \
      -e 's#^\# PREREG38 firebreather driver#\# PREREG45 task driver (copy of PREREG38 run_task_p38.sh md5 '"$(md5sum $S38/scripts/run_task_p38.sh | cut -c1-8)"'; taskmap, arm case, runner, log tag only). PREREG38 firebreather driver#' \
      -e 's#QC_AFAC=\$QC_AFAC SMALL#QC_AFAC=$QC_AFAC RH_A=${QC_RH_A:-unset} RH_B=${QC_RH_B:-unset} SMALL#' > $J/scripts/run_task_p45.sh
rm $J/scripts/.case.txt
grep -q '^  qc_rh) ' $J/scripts/run_task_p45.sh && grep -q '^  qc_rh0) ' $J/scripts/run_task_p45.sh && grep -q runner_p45_fb.R $J/scripts/run_task_p45.sh && ! grep -q p38_ $J/scripts/run_task_p45.sh || { echo "FATAL task driver build"; exit 6; }
D5=$(md5sum $J/scripts/run_task_p45.sh | cut -d' ' -f1); D38=$(md5sum $S38/scripts/run_task_p38.sh | cut -d' ' -f1)
sed -e 's#run_task_p38.sh#run_task_p45.sh#g' -e 's#^\# PREREG38 launcher#\# PREREG45 launcher (PREREG38 launch_p38.sh, driver name only). PREREG38 launcher#' $S38/scripts/launch_p38.sh > $J/scripts/launch_p45.sh
sed -e 's#run_retry_p38.sh#run_retry_p45.sh#g' $S38/home/retry_timeouts_p38.sh > $J/home/retry_timeouts_p45.sh
sed -e 's#run_task_p38.sh#run_task_p45.sh#g' -e "s#$D38#$D5#" -e 's#\[v142p38-retry\]#[v142p45-retry]#g' -e 's#/v142p38/#/v142p45/#g' $S38/home/run_retry_p38.sh > $J/home/run_retry_p45.sh
grep -q "$D5" $J/home/run_retry_p45.sh || { echo "FATAL retry md5"; exit 6; }
grep -q "v142p38\|p38_fit\|p38_one" $J/home/run_retry_p45.sh $J/home/retry_timeouts_p45.sh $J/scripts/launch_p45.sh && { echo "FATAL p38 residue"; grep -n "v142p38\|p38_" $J/home/run_retry_p45.sh $J/home/retry_timeouts_p45.sh $J/scripts/launch_p45.sh; exit 6; } || true
# long run wrapper
sed -e 's#/home/aaron/jobs/v142p44/#/home/aaron/jobs/v142p45/#g' -e "s#D=/home/aaron/jobs/v142p45/scripts/driver_p44.R; chk \$D 7d5da479e5016f8d4f00568c93e9efe0#D=/home/aaron/jobs/v142p45/scripts/driver_p45.R; chk \$D $DM#" \
    -e 's#^  p38_fit) export QC_AFAC=1.242 QC_AFAC_SMALL=1.242 QC_AFAC_LARGE=1.242 QC_AFAC_KNOT=25 ;;#  qc_rh) FF=/home/aaron/jobs/v142p45/fit/gyr142-p45-qcrh-fit_DATA_2026-10-05.csv; chk $FF $(cut -d" " -f1 /home/aaron/jobs/v142p45/logs/fit_md5.txt); export QC_RH_A=$(awk -F, '"'"'$1=="a"{print $3}'"'"' $FF) QC_RH_B=$(awk -F, '"'"'$1=="b"{print $3}'"'"' $FF) QC_RH_RFILL=0.815 ;;#' \
    -e 's#\[p44\]#[p45]#g' -e '1s#^\# PREREG44 task wrapper#\# PREREG45 task wrapper (run_p44.sh with job root, driver and md5, arm case and tag changed). PREREG44 task wrapper#' $S44/scripts/run_p44.sh > $J/scripts/run_p45.sh
grep -q "^  qc_rh) " $J/scripts/run_p45.sh && grep -q driver_p45.R $J/scripts/run_p45.sh && ! grep -q "p38_fit\|driver_p44" $J/scripts/run_p45.sh || { echo "FATAL run_p45 build"; exit 6; }
for p in "$S38/scripts/run_task_p38.sh scripts/run_task_p45.sh" "$S38/scripts/launch_p38.sh scripts/launch_p45.sh" "$S38/home/run_retry_p38.sh home/run_retry_p45.sh" "$S38/home/retry_timeouts_p38.sh home/retry_timeouts_p45.sh" "$S44/scripts/run_p44.sh scripts/run_p45.sh" "$S38/home/work/p38_taskmap_DATA_2026-10-01.csv home/work/p45_taskmap_DATA_2026-10-05.csv"; do
  set -- $p; diff $1 $J/$2 > $J/diffs/$(basename $1)_to_$(basename $2).diff || true; done
cp -p $S38/scripts/2026-10-01_v142_volconv_score_r2.R $S38/scripts/2026-09-29_v142_p23_hkey.R $J/scripts/
echo "BUILD_DONE runner $RM driver $DM task $D5"
