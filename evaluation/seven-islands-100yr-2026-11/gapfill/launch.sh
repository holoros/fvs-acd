#!/bin/bash
# Seven Islands gap-fill driver: patch check, keys, smoke through the queue, then the full FIFO submission. Idempotent.
J=~/jobs/silc_agmbench_100yr_20261117; R=~/restricted/silc_agmbench_gapfill_20261117; S=~/restricted/seven_islands_100yr_20261117
A=~/fvsacd142/state/work/arms; Q=~/bin/fbq
export OMP_NUM_THREADS=1 R_DATATABLE_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
umask 077; cd $J
grep -q 'PC" %in% sp_valid' 01_build_bridge_inputs.R || { sed -i 's/s\[s == "WB"\] <- "PB"$/s[s == "WB"] <- "PB"; s[s == "PC" \& !("PC" %in% sp_valid)] <- "PR"/' 01_build_bridge_inputs.R
  sed -i 's/c(sp_valid, "CE", "WB")/c(sp_valid, "CE", "WB", "PC")/g' 01_build_bridge_inputs.R; }
if [ ! -f $R/KEYS_V2 ]; then rm -rf $R/keys; nice -n 10 Rscript 01_build_bridge_inputs.R $R $A/prod_fix && touch $R/KEYS_V2; fi
echo "keys $(ls $R/keys/c5 | wc -l) md5 builder $(md5sum < 01_build_bridge_inputs.R)"
# research arm folder: PR 30 harness and engines, byte copies, no sample file so every plot runs
G=$R/research; mkdir -p $G/results
for f in AcadianGY_12.11.1.r AcadianGY_13.1.r AcadianGY_14.0.4.r AcadianGY_14.1.r v14_coef_bundle_2026-09-08.rds v141_option3_offline_coefs_r5_2026-09-23.rds run_acd_versions_100yr.R; do cp -n $S/$f $G/; done
cp -n $R/plots.csv $R/trees.csv $G/
( cd $G && md5sum AcadianGY_1*.r *.rds run_acd_versions_100yr.R ) > $J/research_md5.txt
md5sum $A/prod_fix/* $A/x142sb/* ~/fvsacd142/state/work/x142/x142_gseq.csv ~/opt/fvs/bin/FVSne.so $J/bridge_silc.R $R/silc_sdib.csv > $J/bridge_md5.txt
# smoke: 2 plots per bridge arm, 5-year cycles, ingrowth on
if [ ! -f $R/SMOKE_OK ]; then
  for arm in prod_fix x142sb; do $Q run -t 1 -n silc_smoke_$arm -w 3 -- nice -n 10 $J/03_run_bridge.sh smoke_$arm $arm Yes c5 0 1 2; echo "smoke $arm rc=$?"; done
  cd ~/perseus_me && source run/env.sh >/dev/null 2>&1; cd $J
  python3 04_collate_bridge.py smoke_prod_fix ACD-prod-12.5.2 ; python3 04_collate_bridge.py smoke_x142sb ACD-14.2-brmsSDImax
  cat $R/batch/smoke_*/b0/P*/DONE
  n=$(cat $R/results/smoke_prod_fix.csv $R/results/smoke_x142sb.csv | grep -c "ACD-")
  e=$(cat $R/results/smoke_*_errors.csv | grep -c "ACD-")
  if [ "$n" = 84 ] && [ "$e" = 0 ]; then touch $R/SMOKE_OK; else echo "SMOKE_FAIL rows $n errors $e"; tail -30 $R/batch/smoke_prod_fix/b0.rout; exit 1; fi
fi
[ -f $R/SUBMITTED ] && { echo already submitted; exit 0; }
sub(){ n=$1; shift; setsid nohup $Q run -t 1 -n $n -- "$@" > $J/logs/$n.log 2>&1 < /dev/null & sleep 3; }
mkdir -p $J/logs
for arm in prod_fix x142sb; do for s in 0 1; do sub silc_${arm}_ing1_b$s nice -n 10 $J/03_run_bridge.sh ${arm}_ing1 $arm Yes c5 $s 2; done; done
for m in v12.11.1 v13.1-base v14.0.4-L2 v14.1-L2L; do for s in 1 2; do sub silc_${m}_p$s bash -c "cd $G && nice -n 10 Rscript --vanilla run_acd_versions_100yr.R $m 0 $s 2"; done; done
for arm in prod_fix x142sb; do sub silc_${arm}_c100 nice -n 10 $J/03_run_bridge.sh ${arm}_ing1_c100 $arm Yes c100 0 13; done
for arm in prod_fix x142sb; do for s in 0 1; do sub silc_${arm}_ing0_b$s nice -n 10 $J/03_run_bridge.sh ${arm}_ing0 $arm No c5 $s 2; done; done
touch $R/SUBMITTED; echo "SUBMITTED $(date -Iseconds)"; $Q status | head -30
