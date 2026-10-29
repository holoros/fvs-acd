#!/bin/bash
# PREREG45 scoring (run_score_p38.sh with job root, taskmap, arm, plan and tag changed). PREREG38 scoring (modelled on PREREG28b run_score_p28b.sh md5 c1e915b5; job root, taskmap, arm list, scorer r2, plan and
# tag changed; C0 and C1 only, no C2 pass). qc_rh qc_c and qc_fl chunk results are joined and host time limit stands
# replaced by their latest by name retry. Plan rows mirror the PREREG19 plan (tagfr = run frames, c2 FALSE; no tag pairing
# is read by C0 or C1). Scorer r2 (265fc695, unedited) then scores qc_rh and frozen p19_a0111 (the latter
# only for reproduction check R4). New directories only; refuses to overwrite. No coordinates. No em dashes.
set -uo pipefail
J=/home/aaron/jobs/v142p45; H=$J/home; X=/home/aaron/jobs/v142p19/in/xfer; P19=/home/aaron/jobs/v142p19
export OMP_NUM_THREADS=2 R_DATATABLE_NUM_THREADS=2
cd $J; mkdir -p results plan tables
SC=scripts/2026-10-01_v142_volconv_score_r2.R
echo "265fc6950ce3f18da751da8b9fd3dbc2  $SC" | md5sum -c - || exit 4
echo "0b604babd7cbef91afc0ded4b2687431  $H/hw_formrisk_split.R" | md5sum -c - || exit 4
TM=$H/work/p45_taskmap_DATA_2026-10-05.csv
join_arm() { local A=$1 s=$2 f=results/$1/gyr_$1_$2_results.csv
  n=$(awk -F, -v a=$A -v s=$s 'NR>1 && $1<=20 && $2==a && $4==s' $TM | wc -l); k=$(ls $H/out/$A/$s/c*_results.csv 2>/dev/null | wc -l)
  [ "$k" -eq "$n" ] || { echo "FATAL $A $s has $k of $n chunk results"; exit 6; }
  mkdir -p results/$A; [ -e $f ] && { echo "REFUSE $f exists"; exit 5; }
  fs=($(ls $H/out/$A/$s/c*_results.csv | sort)); head -1 ${fs[0]} > $f.main
  for x in "${fs[@]}"; do [ "$(head -1 $x)" = "$(head -1 ${fs[0]})" ] || { echo "FATAL header differs $x"; exit 7; }; tail -n +2 $x >> $f.main; done
  Rscript -e 'suppressMessages(library(data.table)); a <- commandArgs(TRUE); r <- fread(a[1]); r[, STAND := as.character(STAND)]
    rt <- rbindlist(lapply(1:3, function(k) { fs <- list.files(sprintf("%s/out_retry_a%d/%s/%s", a[3], k, a[4], a[5]), "^c[0-9]+_results[.]csv$", full.names = TRUE)
      if (!length(fs)) return(NULL); x <- rbindlist(lapply(fs, fread), fill = TRUE); x[, `:=`(STAND = as.character(STAND), attempt = k)] }), fill = TRUE)
    n <- 0L; if (nrow(rt)) { rt <- rt[order(STAND, -attempt)][!duplicated(STAND)][STAND %in% r$STAND]; n <- nrow(rt); i <- match(rt$STAND, r$STAND); for (cc in names(r)) set(r, i, cc, rt[[cc]]) }
    if (anyDuplicated(r$STAND)) stop("duplicated STAND"); fwrite(r, a[2]); cat(sprintf("%s %s: %d stands, %d replaced by retries, %d still RUN_OK 0\n", a[4], a[5], nrow(r), n, sum(r$RUN_OK != 1)))' $f.main $f $H $A $s || exit 8
  rm -f $f.main; }
for s in qc_c qc_fl; do join_arm qc_rh $s; done
P=plan/p45_plan_fb.csv; [ -e $P ] && { echo "REFUSE $P"; exit 5; }
echo "label,set,arm,res,tree_dirs,fr,tagfr,c2,idx,v0_hard" > $P
for s in qc_c qc_fl; do
  echo "$s,$s,qc_rh,$J/results/qc_rh/gyr_qc_rh_${s}_results.csv,$H/out/qc_rh/$s;$H/out_retry_a1/qc_rh/$s;$H/out_retry_a2/qc_rh/$s;$H/out_retry_a3/qc_rh/$s,$H/magplot/verify/gydbreg20260916/frames,$H/magplot/verify/gydbreg20260916/frames,FALSE,$X/score/work/siteidx_${s}.rds,TRUE" >> $P
  echo "$s,$s,p19_a0111,$P19/results/p19_a0111/gyr_p19_a0111_${s}_results.csv,$P19/home/out/p19_a0111/$s;$P19/home/out_retry_a1/p19_a0111/$s;$P19/home/out_retry_a2/p19_a0111/$s;$P19/home/out_retry_a3/p19_a0111/$s,$P19/home/magplot/verify/gydbreg20260916/frames,$P19/home/magplot/verify/gydbreg20260916/frames,FALSE,$X/score/work/siteidx_${s}.rds,TRUE" >> $P
done
export VC_REFDIR=$H/magplot/verify VC_SPLIT=$H/hw_formrisk_split.R VC_TRT=$X/v142_20260925/p14/out/p14_magp_treatment_DATA_2026-09-26.csv
md5sum $SC $VC_SPLIT $VC_REFDIR/nsvb_emulator_coefs.csv $VC_REFDIR/spcd_spgrpcd.csv $VC_TRT $X/score/work/*.rds $P
VC_OUT=$J/tables VC_PLAN=$J/$P VC_TAG=p45-fb Rscript $SC; rc=$?; echo "SCORE C0 C1 EXIT $rc"; [ $rc -eq 0 ] || exit $rc
for f in tables/*_PROVISIONAL_*.csv; do [ -e "$f" ] && mv -n "$f" "${f/_PROVISIONAL_/_DATA_}"; done
ls tables
echo P45_SCORE_DONE
