#!/bin/bash
J=~/jobs/silc_agmbench_100yr_20261117; R=~/restricted/silc_agmbench_gapfill_20261117; Q=~/bin/fbq; LN5=1.6094379124341003
export OMP_NUM_THREADS=1 R_DATATABLE_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1; umask 077; cd $J
$Q run -t 1 -n silc_bakz_smoke -w 8 -- nice -n 10 ./12_run_bakz_bridge.sh smoke_prod prod_fix 0 0 0 0 75
D=$(ls -d $R/bakz/batch/smoke_prod/b0/B*/ | head -1); cat $D/DONE
python3 - "$D" <<'PY'
import sys, sqlite3, pandas as pd
from pathlib import Path
d=Path(sys.argv[1]); S=pd.read_csv(Path.home()/"restricted/silc_agmbench_gapfill_20261117/bakz/stands.csv").set_index("sid")
t=pd.read_sql("select Year,TPA,DBH from FVS_TreeList",sqlite3.connect(d/"fvsout.db")); y0=t[t.Year==t.Year.min()]
ba=(y0.TPA*0.005454154*y0.DBH**2).sum(); print("SMOKE sid",d.name,"BA0",round(ba,2),"key",round(S.loc[d.name,"ba"],2),"years",t.Year.nunique())
sys.exit(0 if abs(ba-S.loc[d.name,"ba"])<0.02*S.loc[d.name,"ba"] and t.Year.nunique()==21 else 1)
PY
[ $? = 0 ] || { echo BAKZ_SMOKE_FAIL; tail -20 $R/bakz/batch/smoke_prod/b0.rout; exit 1; }
sub(){ n=$1; shift; setsid nohup $Q run -t 1 -n $n -- nice -n 10 "$@" > $J/logs/$n.log 2>&1 < /dev/null & sleep 3; }
sub silc_bakz_fvsne bash -c "cd ~/perseus_me && source run/env.sh >/dev/null 2>&1 && cd $J && python3 11_bakz_native.py FVS-NE"
sub silc_bakz_osm bash -c "cd ~/perseus_me && source run/env.sh >/dev/null 2>&1 && cd $J && python3 11_bakz_native.py OSM"
for s in 0 1; do
  sub silc_bakz_prod_b$s ./12_run_bakz_bridge.sh prod prod_fix 0 0 0 $s 2
  sub silc_bakz_x142_b$s ./12_run_bakz_bridge.sh x142 x142sb 0 0 0 $s 2
  sub silc_bakz_l5_b$s ./12_run_bakz_bridge.sh l5 x143m1l5 1 $LN5 0 $s 2
  sub silc_bakz_l5m2_b$s ./12_run_bakz_bridge.sh l5m2 x143m1l5m2 1 $LN5 1 $s 2
  sub silc_bakz_l0_b$s ./12_run_bakz_bridge.sh l0 x143m1l0 1 0 0 $s 2
  sub silc_bakz_l0m2_b$s ./12_run_bakz_bridge.sh l0m2 x143m1l0m2 1 0 1 $s 2
done
echo "SUBMITTED4 $(date -Iseconds)"
