#!/bin/bash
# PREREG18 scoring of the firebreather arms v141LTig_m175 and v141LTig_m225 (NS four), where their outputs live. Derived
# from ~/jobs/v142p17/scripts/run_score_fb_rev2.sh (md5 6511b0ce): per set results are a plain row bind of the chunk
# results (one header); stands that hit the host time limit are replaced in place by their latest retry (out_retry_a1 to
# a3), in the results and, through the scorer's later directory rule, in the per tree lists. Then the PREREG16 scorer (md5
# 019df238, not edited) through the new plan CSV plan/p18_plan_fb.csv, C0 and C1 (no C2 here), and the PREREG17 structure
# script (md5 14c53082, not edited). Both scripts carry the fixed stamp 2026-09-27 in their output names; this wrapper
# renames the outputs to _DATA_2026-09-28 without changing content. Hard stops on a missing chunk, a header mismatch, a
# duplicated stand or a scorer failure. New directories only; refuses to overwrite. No coordinates. No em dashes.
set -uo pipefail
J=/home/aaron/jobs/v142p18; H=$J/home; ARMS="v141LTig_m175 v141LTig_m225"; SETS="ns_c ns_fl ns_long_c ns_long_fl"
export OMP_NUM_THREADS=2 R_DATATABLE_NUM_THREADS=2
cd $J; mkdir -p results plan tables
echo "019df23877abd9e1aab83831d13322dc  scripts/2026-09-27_v142_volconv_score.R" | md5sum -c - || exit 4
echo "14c530827fd9e8f5685911c9bb1dacb3  scripts/2026-09-27_v142_p17_summ.R" | md5sum -c - || exit 4
echo "0b604babd7cbef91afc0ded4b2687431  $H/hw_formrisk_split.R" | md5sum -c - || exit 4
TM=$H/work/p18_taskmap_DATA_2026-09-28.csv
for A in $ARMS; do mkdir -p results/$A
 for s in $SETS; do
  n=$(awk -F, -v s=$s -v a=$A 'NR>1 && $2==a && $4==s' $TM | wc -l)
  k=$(ls $H/out/$A/$s/c*_results.csv 2>/dev/null | wc -l); [ "$k" -eq "$n" ] || { echo "FATAL $A $s has $k of $n chunk results"; exit 6; }
  f=results/$A/gyr_${A}_${s}_results.csv; [ -e $f ] && { echo "REFUSE $f exists"; exit 5; }
  fs=($(ls $H/out/$A/$s/c*_results.csv | sort)); head -1 ${fs[0]} > $f.main
  for x in "${fs[@]}"; do [ "$(head -1 $x)" = "$(head -1 ${fs[0]})" ] || { echo "FATAL header differs $x"; exit 7; }; tail -n +2 $x >> $f.main; done
  Rscript -e 'suppressMessages(library(data.table)); a <- commandArgs(TRUE); r <- fread(a[1]); r[, STAND := as.character(STAND)]
    rt <- rbindlist(lapply(1:3, function(k) { fs <- list.files(sprintf("%s/out_retry_a%d/%s/%s", a[3], k, a[4], a[5]), "^c[0-9]+_results[.]csv$", full.names = TRUE)
      if (!length(fs)) return(NULL); x <- rbindlist(lapply(fs, fread), fill = TRUE); x[, `:=`(STAND = as.character(STAND), attempt = k)] }), fill = TRUE)
    n <- 0L; if (nrow(rt)) { rt <- rt[order(STAND, -attempt)][!duplicated(STAND)][STAND %in% r$STAND]; n <- nrow(rt); i <- match(rt$STAND, r$STAND); for (cc in names(r)) set(r, i, cc, rt[[cc]]) }
    if (anyDuplicated(r$STAND)) stop("duplicated STAND"); fwrite(r, a[2]); cat(sprintf("%s %s: %d stands, %d replaced by retries, %d still RUN_OK 0\n", a[4], a[5], nrow(r), n, sum(r$RUN_OK != 1)))' $f.main $f $H $A $s || exit 8
  rm -f $f.main
 done
done
PLAN=plan/p18_plan_fb.csv; [ -e $PLAN ] && { echo "REFUSE $PLAN"; exit 5; }
echo "label,set,arm,res,tree_dirs,fr,tagfr,c2,idx,v0_hard" > $PLAN
for A in $ARMS; do for s in $SETS; do
  echo "$s,$s,$A,$J/results/$A/gyr_${A}_${s}_results.csv,$H/out/$A/$s;$H/out_retry_a1/$A/$s;$H/out_retry_a2/$A/$s;$H/out_retry_a3/$A/$s,$H/magplot/verify/gydbreg20260916/frames,,FALSE,$J/in/siteidx_${s}.rds,TRUE" >> $PLAN
done; done
export VC_OUT=$J/tables VC_PLAN=$J/$PLAN VC_REFDIR=$H/magplot/verify VC_SPLIT=$H/hw_formrisk_split.R VC_TAG=p18-fb
md5sum scripts/*.R $VC_SPLIT $VC_REFDIR/nsvb_emulator_coefs.csv $VC_REFDIR/spcd_spgrpcd.csv
Rscript scripts/2026-09-27_v142_volconv_score.R; rc=$?; echo "SCORE EXIT $rc"; [ $rc -eq 0 ] || exit $rc
P17_OUT=$J/tables P17_PLAN=$J/$PLAN P17_TAG=p18-fb Rscript scripts/2026-09-27_v142_p17_summ.R; rc=$?; echo "SUMM EXIT $rc"; [ $rc -eq 0 ] || exit $rc
for f in tables/gyr142-p18-fb-*_PROVISIONAL_2026-09-27.csv tables/gyr142-p18-fb-*_DATA_2026-09-27.csv; do [ -e "$f" ] || continue
  g=${f/_PROVISIONAL_2026-09-27/_DATA_2026-09-28}; g=${g/_DATA_2026-09-27/_DATA_2026-09-28}; mv -n "$f" "$g"; done
for x in scores stands structure K1 gates; do [ -e tables/gyr142-p18-fb-${x}_DATA_2026-09-28.csv ] || { echo "FATAL missing $x table"; exit 9; }; done
echo P18_FB_SCORE_DONE
