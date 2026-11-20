#!/bin/bash
# Bridge arms rerun with ingrowth that can fire: cut point 0 and 5 cm minimum DBH, the research-arm setting. Smoke gate first.
J=~/jobs/silc_agmbench_100yr_20261117; R=~/restricted/silc_agmbench_gapfill_20261117; Q=~/bin/fbq
export OMP_NUM_THREADS=1 R_DATATABLE_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1; umask 077; cd $J
$Q run -t 1 -n silc_smokeT0 -w 6 -- nice -n 10 $J/03_run_bridge_ingT0.sh smokeT0_prod_fix prod_fix Yes c5 0 1 2; echo "smoke rc=$?"
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1; cd $J
python3 04_collate_bridge.py smokeT0_prod_fix ACD-prod-ingT0; cat $R/batch/smokeT0_prod_fix/b0/P*/DONE
python3 - <<'PY'
import pandas as pd
from pathlib import Path
R=Path.home()/"restricted/silc_agmbench_gapfill_20261117/results"
a=pd.read_csv(R/"smokeT0_prod_fix.csv"); b=pd.read_csv(R/"smoke_prod_fix.csv")
m=a.merge(b,on=["plot_id","year_offset"]); print("rows",len(a),"tpa100 T0 vs 0.95:",m[m.year_offset==100][["tpa_x","tpa_y"]].mean().round(1).tolist(),"differs:",bool((m.tpa_x-m.tpa_y).abs().max()>1))
PY
n=$(grep -c "ACD-" $R/results/smokeT0_prod_fix.csv); [ "$n" = 42 ] || { echo SMOKE2_FAIL; tail -20 $R/batch/smokeT0_prod_fix/b0.rout; exit 1; }
for arm in prod_fix x142sb; do for s in 0 1; do setsid nohup $Q run -t 1 -n silc_${arm}_ingT0_b$s -- nice -n 10 $J/03_run_bridge_ingT0.sh ${arm}_ingT0 $arm Yes c5 $s 2 > $J/logs/silc_${arm}_ingT0_b$s.log 2>&1 < /dev/null & sleep 3; done; done
echo "SUBMITTED2 $(date -Iseconds)"
