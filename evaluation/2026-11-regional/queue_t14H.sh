#!/bin/bash
# T14 held-out set H (PREREG_T14), after the gy2 queue. Deviation: ACD7 arms added; 2 NFI QC pairs dropped as duplicates of QC PSPs.
while kill -0 4015890 2>/dev/null; do sleep 60; done; echo "gy2 queue ended $(date -Iseconds)"
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1
F=~/fvsacd142; S=$F/state; T=$F/tools/t14; W=$S/work/x142; J=~/jobs/gy2eval_20261112; A=~/jobs/acd7_port; IDS=$S/restricted/sub/g2H_ids.txt
vb(){ [ -f $S/restricted/runs/$3/pair_rows.csv ] && { echo "skip $3"; return; }
  echo "start $3 $(date -Iseconds)"
  nice -n 10 python3 $T/v_batch.py --set $1 --arm $2 --out $S/restricted/runs/$3 --batch $S/restricted/batch/$3 --workers 2 --ids $IDS > $S/logs/$3.log 2>&1
  echo "end $3 rc=$? $(date -Iseconds)"; }
a7(){ echo "acd7 $3 $(date -Iseconds)"
  ( nice -n 10 Rscript $A/repo6/tests/acd7_arm.R $1 $2 $3 $4 $5 $A/repo6 1 2 > $J/$3_l1.log 2>&1 ) &
  ( nice -n 10 Rscript $A/repo6/tests/acd7_arm.R $1 $2 $3 $4 $5 $A/repo6 2 2 > $J/$3_l2.log 2>&1 ) & wait; echo "acd7 end $3 $(date -Iseconds)"; }
vb g2 prod_fix t14H_prod_fix
V_X142=$W/x142_gseq.csv vb g2 x142 t14H_x142GS
a7 g2 t14H_prod_fix t14H_acd7c compiled prod
a7 g2 t14H_prod_fix t14H_acd7x corrected prod
a7 g2 t14H_prod_fix t14H_acd7xSI corrected si
for sh in "" 7; do
  nice -n 10 python3 $T/t14_score.py --set g2 --base t14H_prod_fix --cand t14H_x142GS,t14H_acd7c,t14H_acd7x,t14H_acd7xSI --tag t14H_main${sh:+_shuf$sh} ${sh:+--shuffle-seed $sh} > $J/score_t14H${sh}.log 2>&1; echo "score rc=$?"
done
echo T14H_DONE
