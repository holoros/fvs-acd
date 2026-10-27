#!/bin/bash
# PREREG49 scoring r2 (modelled on PREREG45 run_score_p45.sh md5 afaa8473 and PREREG22 run_score_p22.sh: job root, taskmap,
# arms, plan and tag changed). v141LTfis chunk results on the NS four are joined and host time limit stands replaced by their
# latest by name retry; scorer r2 (265fc695, unedited) then scores v141LTfis and frozen v141LTfi (PREREG22, read, never rerun;
# scored here so M5 compares like with like and as a reproduction of the PREREG22 C0 and C1 rows); then the PREREG17 structure
# summary (PREREG22 copy 14c53082, unedited) for K1, stems, BA, QMD and TOPHT. Outputs under out/. New files only; refuses to
# overwrite. No coordinates. No em dashes.
set -uo pipefail
J=${P49_ROOT:-/home/aaron/jobs/v142p49}; H=$J/home; P22=/home/aaron/jobs/v142p22; A=v141LTfis
export OMP_NUM_THREADS=1 R_DATATABLE_NUM_THREADS=1
cd $J; mkdir -p out/results out/plan out/tables
SC=scripts/2026-10-01_v142_volconv_score_r2.R; SU=scripts/2026-09-27_v142_p17_summ.R
echo "265fc6950ce3f18da751da8b9fd3dbc2  $SC" | md5sum -c - || exit 4
echo "14c530827fd9e8f5685911c9bb1dacb3  $SU" | md5sum -c - || exit 4
echo "0b604babd7cbef91afc0ded4b2687431  $H/hw_formrisk_split.R" | md5sum -c - || exit 4
TM=$H/work/p49_taskmap_DATA_2026-10-26.csv
join_arm() { local A=$1 s=$2 f=out/results/$1/gyr_$1_$2_results.csv
  n=$(awk -F, -v a=$A -v s=$s 'NR>1 && $1<=36 && $2==a && $4==s' $TM | wc -l); k=$(ls $H/out/$A/$s/c*_results.csv 2>/dev/null | wc -l)
  [ "$k" -eq "$n" ] || { echo "FATAL $A $s has $k of $n chunk results"; exit 6; }
  mkdir -p out/results/$A; [ -e $f ] && { echo "REFUSE $f exists"; exit 5; }
  fs=($(ls $H/out/$A/$s/c*_results.csv | sort)); head -1 ${fs[0]} > $f.main
  for x in "${fs[@]}"; do [ "$(head -1 $x)" = "$(head -1 ${fs[0]})" ] || { echo "FATAL header differs $x"; exit 7; }; tail -n +2 $x >> $f.main; done
  Rscript -e 'suppressMessages(library(data.table)); a <- commandArgs(TRUE); r <- fread(a[1]); r[, STAND := as.character(STAND)]
    rt <- rbindlist(lapply(1:3, function(k) { fs <- list.files(sprintf("%s/out_retry_a%d/%s/%s", a[3], k, a[4], a[5]), "^c[0-9]+_results[.]csv$", full.names = TRUE)
      if (!length(fs)) return(NULL); x <- rbindlist(lapply(fs, fread), fill = TRUE); x[, `:=`(STAND = as.character(STAND), attempt = k)] }), fill = TRUE)
    n <- 0L; if (nrow(rt)) { rt <- rt[order(STAND, -attempt)][!duplicated(STAND)][STAND %in% r$STAND]; n <- nrow(rt); i <- match(rt$STAND, r$STAND); for (cc in names(r)) set(r, i, cc, rt[[cc]]) }
    if (anyDuplicated(r$STAND)) stop("duplicated STAND"); fwrite(r, a[2]); cat(sprintf("%s %s: %d stands, %d replaced by retries, %d still RUN_OK 0\n", a[4], a[5], nrow(r), n, sum(r$RUN_OK != 1)))' $f.main $f $H $A $s || exit 8
  rm -f $f.main; }
for s in ns_c ns_fl ns_long_c ns_long_fl; do join_arm $A $s; done
P=out/plan/p49_plan_fb.csv; [ -e $P ] && { echo "REFUSE $P"; exit 5; }
echo "label,set,arm,res,tree_dirs,fr,tagfr,c2,idx,v0_hard" > $P
for s in ns_c ns_fl ns_long_c ns_long_fl; do
  echo "$s,$s,$A,$J/out/results/$A/gyr_${A}_${s}_results.csv,$H/out/$A/$s;$H/out_retry_a1/$A/$s;$H/out_retry_a2/$A/$s;$H/out_retry_a3/$A/$s,$H/magplot/verify/gydbreg20260916/frames,,FALSE,$P22/in/siteidx_${s}.rds,TRUE" >> $P
  echo "$s,$s,v141LTfi,$P22/results/v141LTfi/gyr_v141LTfi_${s}_results.csv,$P22/home/out/v141LTfi/$s;$P22/home/out_retry_a1/v141LTfi/$s;$P22/home/out_retry_a2/v141LTfi/$s;$P22/home/out_retry_a3/v141LTfi/$s,$P22/home/magplot/verify/gydbreg20260916/frames,,FALSE,$P22/in/siteidx_${s}.rds,TRUE" >> $P
done
export VC_OUT=$J/out/tables VC_PLAN=$J/$P VC_REFDIR=$H/magplot/verify VC_SPLIT=$H/hw_formrisk_split.R VC_TAG=p49-fb
md5sum $SC $SU $VC_SPLIT $VC_REFDIR/nsvb_emulator_coefs.csv $VC_REFDIR/spcd_spgrpcd.csv $P22/in/siteidx_*.rds $P
Rscript $SC; rc=$?; echo "SCORE EXIT $rc"; [ $rc -eq 0 ] || exit $rc
P17_OUT=$J/out/tables P17_PLAN=$J/$P P17_TAG=p49-fb Rscript $SU; rc=$?; echo "SUMM EXIT $rc"; [ $rc -eq 0 ] || exit $rc
for f in out/tables/*_PROVISIONAL_*.csv; do [ -e "$f" ] && mv -n "$f" "${f/_PROVISIONAL_/_DATA_}"; done
ls out/tables
echo P49_SCORE_DONE
