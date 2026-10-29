#!/bin/bash
# PREREG50 build (plan revision 1, md5 6ea850d4). (1) Bundle: the PREREG19 bundle files copied from ~/jobs/v142p19/home;
# the md5 lists of source and copy must be identical (lookup L1). (2) home/runner_p50_fb.R = runner_htfix_fb.R (4e6a2997)
# with exactly two edits, each asserted to apply once: the P50_TRACE line after line 433 and the P50_ONESTEP loop length on
# line 437; the diff is kept. (3) Task driver: scripts/run_task_p50_TEMPLATE.sh with the runner md5 filled in, written to
# scripts/run_task_p50.sh; its environment block must equal lines 17 to 33 of run_task_p19.sh (ac029e4e) verbatim.
# (4) Taskmap: the 19 qc_c chunks of p19_a0111 for each of g2, e1, s2 (57 tasks). Refuses if home exists. No em dashes.
set -euo pipefail
S=/home/aaron/jobs/v142p19; J=/home/aaron/jobs/v142p50
[ -e $J/home ] && { echo "REFUSE $J/home exists"; exit 3; }
grep -q "PREREG50 revision 1 registered" $J/logs/prereg_md5.txt || { echo "REFUSE plan not registered"; exit 4; }
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); [ "$m" = "$2" ] || { echo "FATAL md5 $1 $m != $2"; exit 4; }; }
chk $S/home/runner_htfix_fb.R 4e6a29971922b1f7a0397cc91ff56f84
chk $S/scripts/run_task_p19.sh ac029e4e6eeb1d71f1784b423c8575fc
chk $S/home/AcadianGY_13.1.r 5894df6013c701d09e7ba67ba6c2f090
chk $S/home/v14_1_20260923/AcadianGY_14.1.r 0bf27dde81240e6bdf59c9a90f0051bd
mkdir -p $J/home/work $J/home/logs $J/diffs
LIST="AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R magplot v14_0_4_20260917 v14_1_20260923"
cd $S/home; for f in AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R; do cp -p $f $J/home/; done
cp -a magplot v14_0_4_20260917 v14_1_20260923 $J/home/
( cd $S/home && find $LIST -type f -print0 | sort -z | xargs -0 md5sum ) > $J/logs/bundle_md5_source.txt
( cd $J/home && find $LIST -type f -print0 | sort -z | xargs -0 md5sum ) > $J/logs/bundle_md5_p50.txt
cmp $J/logs/bundle_md5_source.txt $J/logs/bundle_md5_p50.txt || { echo "FATAL bundle copy differs from source"; exit 6; }
echo "bundle md5 identical to source ($S/home): $(wc -l < $J/logs/bundle_md5_p50.txt) files" > $J/logs/bundle_check.txt
python3 - <<'PY'
src = "/home/aaron/jobs/v142p50/home/runner_htfix_fb.R"; dst = "/home/aaron/jobs/v142p50/home/runner_p50_fb.R"
t = open(src).read()
a = '    if (identical(Sys.getenv("ING_MIN_FROM_SCORE", "0"), "1")) ops$ingrowth.min.dbh <- GYR_smd(p)  # PREREG9: ingrowth threshold = scoring threshold\n'
a2 = a + '    if (nzchar(Sys.getenv("P50_TRACE"))) cat(sprintf("\\"%s\\",%.17g,%.17g\\n", sid, ops$ingrowth.min.dbh, GYR_smd(p)), file = Sys.getenv("P50_TRACE"), append = TRUE)  # PREREG50 G3 trace\n'
b = 'for(yr in seq_len(iv)){'
b2 = 'for(yr in seq_len(if (identical(Sys.getenv("P50_ONESTEP", "0"), "1")) 1L else iv)){'
assert t.count(a) == 1, ("edit a", t.count(a)); assert t.count(b) == 1, ("edit b", t.count(b))
t = t.replace(a, a2).replace(b, b2)
open(dst, "w").write(t); print("edited", dst)
PY
diff $J/home/runner_htfix_fb.R $J/home/runner_p50_fb.R > $J/diffs/runner_htfix_fb.R_to_runner_p50_fb.R.diff || true
[ "$(grep -c '^[<>]' $J/diffs/runner_htfix_fb.R_to_runner_p50_fb.R.diff)" = 3 ] || { echo "FATAL runner diff is not the two edits"; exit 6; }
RM=$(md5sum $J/home/runner_p50_fb.R | cut -d' ' -f1)
[ -e $J/scripts/run_task_p50.sh ] && { echo "REFUSE run_task_p50.sh exists"; exit 3; }
RM=$RM python3 - <<'PY'
import os
p19 = open("/home/aaron/jobs/v142p19/scripts/run_task_p19.sh").read().split("\n")[16:33]
assert p19[0].startswith("export OMP_NUM_THREADS=1") and p19[-1].startswith('case "$SET" in qc_c|qc_fl|nb_c)'), "source block bounds"
t = open("/home/aaron/jobs/v142p50/scripts/run_task_p50_TEMPLATE.sh").read()
assert t.count("__P19_ENV_BLOCK__\n") == 1 and t.count("__RUNNER_MD5__") == 1
t = t.replace("__P19_ENV_BLOCK__\n", "\n".join(p19) + "\n").replace("__RUNNER_MD5__", os.environ["RM"])
open("/home/aaron/jobs/v142p50/scripts/run_task_p50.sh", "w").write(t)
print("driver written; environment block verbatim: %d lines" % len(p19))
PY
diff $S/scripts/run_task_p19.sh $J/scripts/run_task_p50.sh > $J/diffs/run_task_p19.sh_to_run_task_p50.sh.diff || true
TM=$J/home/work/p50_taskmap_DATA_2026-10-28.csv
awk -F, 'NR>1 && $2=="p19_a0111" && $4=="qc_c"' $S/home/work/p19_taskmap_DATA_2026-09-28.csv > $J/home/work/.p19rows
[ "$(wc -l < $J/home/work/.p19rows)" = 19 ] && [ "$(tail -1 $J/home/work/.p19rows | cut -d, -f6)" = 380 ] || { echo "FATAL p19 qc_c taskmap rows"; exit 6; }
echo "task,COL,CHUNK,SET,FROM,TO" > $TM; n=0
for A in g2 e1 s2; do while IFS=, read -r t c k s f to; do n=$((n+1)); echo "$n,$A,$k,$s,$f,$to" >> $TM; done < $J/home/work/.p19rows; done
rm $J/home/work/.p19rows; seq 1 57 > $J/home/work/p50_ids.txt
echo "BUILD_DONE runner $RM driver $(md5sum $J/scripts/run_task_p50.sh | cut -d' ' -f1) taskmap $(md5sum $TM | cut -d' ' -f1) tasks $n"
