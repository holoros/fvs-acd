#!/bin/bash
# PREREG28 scoring (copy of PREREG23 run_score_p23.sh, itself a copy of PREREG19 run_score_p19.sh). For every PREREG28 arm, qc_c and qc_fl: chunk results are joined
# and host time limit stands are replaced by their latest by name retry (out_retry_a1 to a3). Then the PREREG16 scorer (md5
# 019df238, unchanged) scores C0 and C1 (tables/, hard stops live) and, in a separate pass that cannot block the verdict,
# C2 on the tag stable QC frames (tables_c2/). New directories only; refuses to overwrite. No coordinates. No em dashes.
set -uo pipefail
J=/home/aaron/jobs/v142p28; H=$J/home; X=/home/aaron/jobs/v142p19/in/xfer
export OMP_NUM_THREADS=2 R_DATATABLE_NUM_THREADS=2
cd $J; mkdir -p results plan tables tables_c2
echo "019df23877abd9e1aab83831d13322dc  scripts/2026-09-27_v142_volconv_score.R" | md5sum -c - || exit 4
echo "0b604babd7cbef91afc0ded4b2687431  $H/hw_formrisk_split.R" | md5sum -c - || exit 4
TM=$H/work/p28_taskmap_DATA_2026-09-30.csv
join_arm() { local A=$1 s=$2 f=results/$1/gyr_$1_$2_results.csv
  n=$(awk -F, -v a=$A -v s=$s 'NR>1 && $1<=40 && $2==a && $4==s' $TM | wc -l); k=$(ls $H/out/$A/$s/c*_results.csv 2>/dev/null | wc -l)
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
ARMS="p28_g0 p28_cand"
for A in $ARMS; do for s in qc_c qc_fl; do join_arm $A $s; done; done
mk_plan() { local P=$1 c2=$2; [ -e $P ] && { echo "REFUSE $P"; exit 5; }
  echo "label,set,arm,res,tree_dirs,fr,tagfr,c2,idx,v0_hard" > $P
  for A in $ARMS; do for s in qc_c qc_fl; do
    echo "$s,$s,$A,$J/results/$A/gyr_${A}_${s}_results.csv,$H/out/$A/$s;$H/out_retry_a1/$A/$s;$H/out_retry_a2/$A/$s;$H/out_retry_a3/$A/$s,$H/magplot/verify/gydbreg20260916/frames,$H/magplot/verify/gydbreg20260916/frames,$c2,$X/score/work/siteidx_${s}.rds,TRUE" >> $P
  done; done; }
mk_plan plan/p28_plan_fb.csv FALSE; mk_plan plan/p28_plan_fb_c2.csv TRUE
export VC_REFDIR=$H/magplot/verify VC_SPLIT=$H/hw_formrisk_split.R VC_TRT=$X/v142_20260925/p14/out/p14_magp_treatment_DATA_2026-09-26.csv
md5sum scripts/*.R $VC_SPLIT $VC_REFDIR/nsvb_emulator_coefs.csv $VC_REFDIR/spcd_spgrpcd.csv $VC_TRT $X/score/work/*.rds
VC_OUT=$J/tables VC_PLAN=$J/plan/p28_plan_fb.csv VC_TAG=p28-fb Rscript scripts/2026-09-27_v142_volconv_score.R; rc=$?; echo "SCORE C0 C1 EXIT $rc"; [ $rc -eq 0 ] || exit $rc
for f in tables/*_PROVISIONAL_*.csv; do [ -e "$f" ] && mv -n "$f" "${f/_PROVISIONAL_/_DATA_}"; done
VC_OUT=$J/tables_c2 VC_PLAN=$J/plan/p28_plan_fb_c2.csv VC_TAG=p28-fb-c2 Rscript scripts/2026-09-27_v142_volconv_score.R; echo "SCORE C2 EXIT $? (reported only)"
for f in tables_c2/*_PROVISIONAL_*.csv; do [ -e "$f" ] && mv -n "$f" "${f/_PROVISIONAL_/_DATA_}"; done
echo P28_SCORE_DONE
