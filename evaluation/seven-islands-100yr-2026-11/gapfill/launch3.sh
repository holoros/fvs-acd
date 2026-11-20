#!/bin/bash
J=~/jobs/silc_agmbench_100yr_20261117; R=~/restricted/silc_agmbench_gapfill_20261117; Q=~/bin/fbq; LN5=1.6094379124341003
export OMP_NUM_THREADS=1 R_DATATABLE_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1; umask 077; cd $J
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1; cd $J
python3 - <<'PY'
import pandas as pd, os
from pathlib import Path
R=Path.home()/"restricted/silc_agmbench_gapfill_20261117"
lm=pd.read_csv(Path.home()/"jobs/m143/fit_M1A2/level_map.csv",dtype=str); own=set(lm.l3[lm.assigned_level.str.startswith("L3:")])
d=pd.read_csv(R/"silc_sdib.csv",dtype=str); d["l3o"]=d.l3.where(d.l3.isin(own),"")
d[["sid"]].assign(l3=d.l3o).to_csv(R/"silc_eco.csv",index=False); os.chmod(R/"silc_eco.csv",0o600)
print("eco",len(d),d.l3o.replace("","REF").value_counts().to_dict())
PY
# identity with switches off (2 plots) against the x142sb ingrowth rerun, then a 2-plot smoke of the full arm
$Q run -t 1 -n silc_x143_ident -w 6 -- nice -n 10 ./09_run_bridge_x143.sh x143_ident_off x143m1l5 0 0 0 0 1 2
$Q run -t 1 -n silc_x143_smoke -w 6 -- nice -n 10 ./09_run_bridge_x143.sh x143_smoke_l5m2 x143m1l5m2 1 $LN5 1 0 1 2
python3 04_collate_bridge.py x143_ident_off ident | head -1; python3 04_collate_bridge.py x143_smoke_l5m2 smoke
python3 - <<'PY'
import pandas as pd
from pathlib import Path
R=Path.home()/"restricted/silc_agmbench_gapfill_20261117/results"
a=pd.read_csv(R/"x143_ident_off.csv"); b=pd.read_csv(R/"x142sb_ingT0.csv"); m=a.merge(b,on=["plot_id","year_offset"])
print("IDENT rows",len(m),"max|dBA|",round(float((m.ba_ft2ac_x-m.ba_ft2ac_y).abs().max()),4),"max|dTPA|",round(float((m.tpa_x-m.tpa_y).abs().max()),4))
PY
n=$(grep -c "smoke" $R/results/x143_smoke_l5m2.csv); [ "$n" = 42 ] || { echo SMOKE3_FAIL; tail -25 $R/batch/x143_smoke_l5m2/b0.rout; exit 1; }
sub(){ n=$1; shift; setsid nohup $Q run -t 1 -n $n -- nice -n 10 "$@" > $J/logs/$n.log 2>&1 < /dev/null & sleep 3; }
for s in 0 1; do sub silc_x143l5_b$s ./09_run_bridge_x143.sh x143m1l5_ingT0 x143m1l5 1 $LN5 0 $s 2; done
for s in 0 1; do sub silc_x143l5m2_b$s ./09_run_bridge_x143.sh x143m1l5m2_ingT0 x143m1l5m2 1 $LN5 1 $s 2; done
for s in 0 1; do sub silc_x143l0_b$s ./09_run_bridge_x143.sh x143m1l0_ingT0 x143m1l0 1 0 0 $s 2; done
for s in 0 1; do sub silc_x143l0m2_b$s ./09_run_bridge_x143.sh x143m1l0m2_ingT0 x143m1l0m2 1 0 1 $s 2; done
echo "SUBMITTED3 $(date -Iseconds)"
