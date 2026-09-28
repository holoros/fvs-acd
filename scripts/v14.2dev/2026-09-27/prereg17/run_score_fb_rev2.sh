#!/bin/bash
# PREREG17 scoring of the firebreather arm v141LTig_m30 (NS four), where its outputs live. Revision 2: stands that hit the
# host time limit are replaced by their latest retry (out_retry_a1 to a3) in the results and the per tree lists. Assembles per set results from
# chunk results (the bench aggregate is a plain row bind with one header), then runs the PREREG16 scorer (md5 019df238,
# copied from ~/jobs/v142vc/scripts, not edited) and p17_summ.R. C2 is not available here (no pass 28 tag frames). New
# directories only; refuses to overwrite. No coordinates. No em dashes.
set -uo pipefail
J=/home/aaron/jobs/v142p17; H=$J/home; A=v141LTig_m30
export OMP_NUM_THREADS=4 R_DATATABLE_NUM_THREADS=4
cd $J; mkdir -p results/$A plan tables
echo "019df23877abd9e1aab83831d13322dc  scripts/2026-09-27_v142_volconv_score.R" | md5sum -c - || exit 4
echo "0b604babd7cbef91afc0ded4b2687431  $H/hw_formrisk_split.R" | md5sum -c - || exit 4
for s in ns_c ns_fl ns_long_c ns_long_fl; do
  n=$(awk -F, -v s=$s 'NR>1 && $2=="v141LTig_m30" && $4==s' $H/work/p17_taskmap_DATA_2026-09-27.csv | wc -l)
  k=$(ls $H/out/$A/$s/c*_results.csv 2>/dev/null | wc -l); [ "$k" -eq "$n" ] || { echo "FATAL $s has $k of $n chunk results"; exit 6; }
  f=results/$A/gyr_${A}_${s}_results.csv; [ -e $f ] && { echo "REFUSE $f exists"; exit 5; }
  fs=($(ls $H/out/$A/$s/c*_results.csv | sort)); head -1 ${fs[0]} > $f.main
  for x in "${fs[@]}"; do [ "$(head -1 $x)" = "$(head -1 ${fs[0]})" ] || { echo "FATAL header differs $x"; exit 7; }; tail -n +2 $x >> $f.main; done
  Rscript -e 'suppressMessages(library(data.table)); a <- commandArgs(TRUE); r <- fread(a[1]); r[, STAND := as.character(STAND)]
    rt <- rbindlist(lapply(1:3, function(k) { fs <- list.files(sprintf("%s/out_retry_a%d/%s/%s", a[3], k, a[4], a[5]), "^c[0-9]+_results[.]csv$", full.names = TRUE)
      if (!length(fs)) return(NULL); x <- rbindlist(lapply(fs, fread), fill = TRUE); x[, `:=`(STAND = as.character(STAND), attempt = k)] }), fill = TRUE)
    n <- 0L; if (nrow(rt)) { rt <- rt[order(STAND, -attempt)][!duplicated(STAND)][STAND %in% r$STAND]; n <- nrow(rt); i <- match(rt$STAND, r$STAND); for (cc in names(r)) set(r, i, cc, rt[[cc]]) }   # in place: row order, and so the site bootstrap draws, unchanged
    if (anyDuplicated(r$STAND)) stop("duplicated STAND"); fwrite(r, a[2]); cat(sprintf("%s: %d stands, %d replaced by retries, %d still RUN_OK 0\n", a[5], nrow(r), n, sum(r$RUN_OK != 1)))' $f.main $f $H $A $s || exit 8
  rm -f $f.main
done
PLAN=plan/p17_plan_fb.csv; [ -e $PLAN ] && { echo "REFUSE $PLAN"; exit 5; }
echo "label,set,arm,res,tree_dirs,fr,tagfr,c2,idx,v0_hard" > $PLAN
for s in ns_c ns_fl ns_long_c ns_long_fl; do echo "$s,$s,$A,$J/results/$A/gyr_${A}_${s}_results.csv,$H/out/$A/$s;$H/out_retry_a1/$A/$s;$H/out_retry_a2/$A/$s;$H/out_retry_a3/$A/$s,$H/magplot/verify/gydbreg20260916/frames,,FALSE,$J/in/siteidx_${s}.rds,TRUE" >> $PLAN; done
export VC_OUT=$J/tables VC_PLAN=$J/$PLAN VC_REFDIR=$H/magplot/verify VC_SPLIT=$H/hw_formrisk_split.R VC_TAG=p17-fb
md5sum scripts/*.R $VC_SPLIT $VC_REFDIR/nsvb_emulator_coefs.csv $VC_REFDIR/spcd_spgrpcd.csv
Rscript scripts/2026-09-27_v142_volconv_score.R; rc=$?; echo "SCORE EXIT $rc"; [ $rc -eq 0 ] || exit $rc
P17_OUT=$J/tables P17_PLAN=$J/$PLAN P17_TAG=p17-fb Rscript scripts/2026-09-27_v142_p17_summ.R; rc=$?; echo "SUMM EXIT $rc"; [ $rc -eq 0 ] || exit $rc
for f in tables/*_PROVISIONAL_*.csv; do mv -n "$f" "${f/_PROVISIONAL_/_DATA_}"; done
echo P17_FB_SCORE_DONE
