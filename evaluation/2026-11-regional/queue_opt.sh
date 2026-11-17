#!/bin/bash
# Optional 14.2 G-only arm (Aaron 16:53 "run optional"), after queue_vol; then all-pairs bootstrap scores with every arm. q14 waits for OPT_DONE.
until grep -q VOL_DONE ~/jobs/gy2eval_20261112/queue_vol.log 2>/dev/null; do sleep 120; done; echo "vol queue ended $(date -Iseconds)"
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1
F=~/fvsacd142; S=$F/state; W=$S/work/x142; J=~/jobs/gy2eval_20261112
run(){ [ -f $S/restricted/runs/$4/pair_rows.csv ] && { echo "skip $4"; return; }; echo "start $4 $(date -Iseconds)"
  rm -rf $S/restricted/batch/$4 $S/restricted/runs/$4
  V_X142=$W/x142_gonly.csv nice -n 10 python3 $1 --set $2 --arm x142 --out $S/restricted/runs/$4 --batch $S/restricted/batch/$4 --workers 2 $3 > $S/logs/$4.log 2>&1; echo "end $4 rc=$? $(date -Iseconds)"; }
run $F/tools/v26_V/v_batch.py gy2 "" gyxG_gy2
run $F/tools/v26_V/v_batch.py gy2L "" gyxG_gy2L
run $F/tools/t14/v_batch.py g2 "--ids $S/restricted/sub/g2H_ids.txt" t14H_x142G
vs(){ echo "vol $*"; nice -n 10 python3 $J/vol_score.py "$@" > $J/out/vol_$4.log 2>&1; echo rc=$?; }
vs gy2 gyp_gy2 gyx_gy2,gyxG_gy2,gycsi_gy2,gya7c_gy2,gya7xH_gy2,gya7xSIH_gy2 gy2_all
vs gy2L gyp_gy2L gyx_gy2L,gyxG_gy2L,gya7c_gy2L,gya7x_gy2L,gya7xSI_gy2L gy2L_all
vs g2 t14H_prod_fix t14H_x142GS,t14H_x142G,t14H_prodcsi,t14H_acd7c,t14H_acd7x,t14H_acd7xSI t14H_all
vs reg r0e_reg_prod_fix x142fullGS_reg,x142fullG_reg,acd7c_reg,acd7xH_reg,acd7cSI_reg reg_all
echo OPT_DONE
