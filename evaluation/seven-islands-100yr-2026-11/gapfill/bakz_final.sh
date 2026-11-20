#!/bin/bash
cd ~/jobs/silc_agmbench_100yr_20261117
source ~/perseus_me/run/env.sh 2>/dev/null
~/bin/fbq run -t 1 -n silc_bakz_assess -- python3 13_bakz_assess.py > bakz_assess.log 2>&1
~/bin/fbq run -t 1 -n silc_bakz_figs -- Rscript 14_bakz_figures.R > bakz_figs.log 2>&1
for f in bakz_out/traj_*.csv; do a=$(basename $f .csv); a=${a#traj_}
  python3 -c "import pandas as pd,sys; d=pd.read_csv('$f'); d=d.rename(columns={'label':'origin','year':'age'}); d.to_csv('bakz_out/chk_in_$a.csv',index=False)"
  Rscript ~/jobs/acd_bakuzis/bakuzis_check_step-aware_FINAL_2026-09-07.R bakz_out/chk_in_$a.csv 0.40 0.10 > bakz_out/check_$a.txt 2>&1
  rm -f bakz_out/chk_in_$a.csv
done
echo BAKZ_FINAL_DONE >> bakz_assess.log
