#!/bin/bash
# Amendment 3a: regional comparators (no R), then scoring
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1
J=~/jobs/gy2eval_20261112; B=~/fvsacd142/state/restricted/batch
cr(){ [ -f $B/$3/meta.json ] && { echo "skip $3"; return; }; echo "start $3 $(date -Iseconds)"; nice -n 10 python3 $J/cmp_run.py --set $1 --arm $2 --run $3 --workers 2 $4 > $J/out/cmp_$3.log 2>&1; echo "end $3 rc=$? $(date -Iseconds)"; }
cr reg fvs_base cmfb_reg; cr reg fvs_regional cmfr_reg; cr reg conus_spdep cmcs_reg
cr reg osm cmos_reg "--only-sets pef_c,ctrn_c,baxter_c,mnap_c,silc_l_c"
vs(){ echo "vol $4 $(date -Iseconds)"; nice -n 10 python3 $J/vol_score.py "$@" > $J/out/vol_$4.log 2>&1; echo rc=$?; }
R=x142fullGS_reg,x142fullG_reg,acd7c_reg,acd7xH_reg,acd7cSI_reg,cmfb_reg,cmfr_reg,cmcs_reg
vs reg r0e_reg_prod_fix $R reg_cmp
vs reg r0e_reg_prod_fix $R,cmos_reg reg_cmp_me
echo REG_DONE $(date -Iseconds)
