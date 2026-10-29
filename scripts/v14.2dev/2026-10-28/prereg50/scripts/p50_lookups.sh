#!/bin/bash
# PREREG50 lookups L1 to L3 (read only), written before any arm runs. L1: md5 of every source and copy named in the plan.
# L2: candidate records of the ingrowth fit data threshold range on firebreather (file names only; read afterwards and the
# finding written to logs/lookups_L2.txt). L3 (gate G7): files under ~/jobs/*/scripts/, ~/jobs/*/home/*.sh,
# ~/jobs/*/home/logs/ and ~/jobs/*/logs/ (v142p50 excluded) that contain ING_MIN_FROM_SCORE=1, flagged as QC when they also
# name qc_c or qc_fl. Output carries paths only, no stand names. No em dashes.
set -uo pipefail
J=/home/aaron/jobs/v142p50; OUT=$J/logs; cd /home/aaron/jobs
[ -e $OUT/lookups_L1_md5.txt ] && { echo "REFUSE lookups exist"; exit 3; }
{ echo "# L1 md5 of sources and copies ($(date -Iseconds))"
  md5sum v142p19/home/runner_htfix_fb.R v142p19/scripts/run_task_p19.sh v142p19/home/AcadianGY_13.1.r \
    v142p19/home/v14_0_4_20260917/AcadianGY_14.0.4.r v142p19/home/v14_1_20260923/AcadianGY_14.1.r \
    v142p19/home/magplot/verify/p4e/model_b0b1b2.r v142p19/results/p19_a0111/gyr_p19_a0111_qc_c_results.csv \
    v142p19/tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv v142p45/scripts/2026-09-29_v142_p23_hkey.R \
    v142p45/scripts/2026-10-01_v142_volconv_score_r2.R v142p22/scripts/2026-09-27_v142_p17_summ.R \
    v142p14/in/pass28qc/bench_gyr_qc_c_tree_init.csv v142p14/in/pass28qc/bench_gyr_qc_c_tree_t2.csv \
    v142p48/scripts/p48_split.R v142p48/scripts/p48_boot.R \
    v142p50/home/runner_htfix_fb.R v142p50/home/runner_p50_fb.R v142p50/home/AcadianGY_13.1.r \
    v142p50/home/v14_1_20260923/AcadianGY_14.1.r v142p50/scripts/run_task_p50.sh v142p50/home/work/p50_taskmap_DATA_2026-10-28.csv
  echo "ingrowth matches in the 14.1 overlay copy: $(grep -c -i ingrowth v142p50/home/v14_1_20260923/AcadianGY_14.1.r)"
  cat $J/logs/bundle_check.txt; } > $OUT/lookups_L1_md5.txt
## L2: candidate files (names only)
{ echo "# L2 candidates ($(date -Iseconds)): files naming the Li, Weiskittel and Kershaw 2011 ingrowth model or an ingrowth fit threshold"
  timeout 600 grep -rIl -i -E "Li, R; Weiskittel|annualized occurrence, frequency, and composition of ingrowth|ingrowth (fit|fitting) (data|threshold)|threshold range.{0,40}ingrowth|ingrowth.{0,40}threshold range" \
    --include=*.md --include=*.R --include=*.r --include=*.txt --include=*.csv /home/aaron/jobs /home/aaron/magplot 2>/dev/null | grep -v '/v142p50/' | sort | head -400
  echo "# git clones under home (depth 3) whose path names fvs or acd:"; find /home/aaron -maxdepth 3 -name .git -type d 2>/dev/null | grep -i -E 'fvs|acd' ; echo "# end"; } > $OUT/lookups_L2_candidates.txt
## L3: G7 search
{ echo "file,qc_set_named"
  timeout 900 grep -rlI --exclude-dir=v142p50 "ING_MIN_FROM_SCORE=1" /home/aaron/jobs/*/scripts/ /home/aaron/jobs/*/home/logs/ /home/aaron/jobs/*/logs/ 2>/dev/null | grep -v '/v142p50/' | sort -u > $OUT/.g7a
  ls /home/aaron/jobs/*/home/*.sh 2>/dev/null | grep -v '/v142p50/' | xargs -r grep -lI "ING_MIN_FROM_SCORE=1" >> $OUT/.g7a
  sort -u $OUT/.g7a | while read f; do if grep -qI -E "qc_c|qc_fl" "$f"; then q=TRUE; else q=FALSE; fi; echo "$f,$q"; done; rm -f $OUT/.g7a; } > $OUT/lookups_G7.csv
echo "LOOKUPS_DONE $(date -Iseconds) L2 candidates $(grep -vc '^#' $OUT/lookups_L2_candidates.txt) G7 files $(($(wc -l < $OUT/lookups_G7.csv)-1)) of which QC $(grep -c ',TRUE$' $OUT/lookups_G7.csv)"
