#!/bin/bash
# gy2 evaluation queue, one compute job at a time, nice 10 (firebreather: at most two R processes; v_batch uses two workers)
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1
F=~/fvsacd142; S=$F/state; T=$F/tools/v26_V; W=$S/work/x142; J=~/jobs/gy2eval_20261112; A=~/jobs/acd7_port
vb(){ [ -f $S/restricted/runs/$3/pair_rows.csv ] && { echo "skip $3"; return; }
  echo "start $3 $(date -Iseconds)"
  nice -n 10 python3 $T/v_batch.py --set $1 --arm $2 --out $S/restricted/runs/$3 --batch $S/restricted/batch/$3 --workers 2 > $S/logs/$3.log 2>&1
  echo "end $3 rc=$? $(date -Iseconds)"; }
a7(){ echo "acd7 $3 $(date -Iseconds)"
  ( nice -n 10 Rscript $A/repo6/tests/acd7_arm.R $1 $2 $3 $4 $5 $A/repo6 1 2 > $J/$3_l1.log 2>&1 ) &
  ( nice -n 10 Rscript $A/repo6/tests/acd7_arm.R $1 $2 $3 $4 $5 $A/repo6 2 2 > $J/$3_l2.log 2>&1 ) & wait; echo "acd7 end $3 $(date -Iseconds)"; }
sc(){ echo "score $*"; nice -n 10 python3 $F/tools/reg_score.py "$@" > $J/score_$(echo "$@" | sed 's/.*--tag //;s/ .*//').log 2>&1; echo rc=$?; }
for s in gy2 gy2L; do
  vb $s prod_fix gyp_${s}
  V_X142=$W/x142_gseq.csv vb $s x142 gyx_${s}
  a7 $s gyp_${s} gya7c_${s} compiled prod
  a7 $s gyp_${s} gya7x_${s} corrected prod
  a7 $s gyp_${s} gya7xSI_${s} corrected si
  sc --set $s --base gyp_${s} --cand gyx_${s},gya7c_${s},gya7x_${s},gya7xSI_${s} --tag ${s}_main
  sc --set $s --base gyp_${s} --cand gyx_${s},gya7c_${s},gya7x_${s},gya7xSI_${s} --tag ${s}_main_shuf7 --shuffle-seed 7
done
V_X142=$W/x142_gonly.csv vb gy2 x142 gyxG_gy2
sc --set gy2 --base gyp_gy2 --cand gyxG_gy2,gyx_gy2 --tag gy2_G
echo GY2_DONE
