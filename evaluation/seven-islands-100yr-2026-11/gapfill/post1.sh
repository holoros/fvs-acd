#!/bin/bash
J=~/jobs/silc_agmbench_100yr_20261117; R=~/restricted/silc_agmbench_gapfill_20261117
cd $J; for f in logs/*.log; do echo "== $f: $(tail -1 $f | cut -c1-150)"; done
~/bin/fbq log 25 2>&1 | cut -c1-160
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1; cd $J
python3 04_collate_bridge.py prod_fix_ing1 ACD-prod-12.5.2
python3 04_collate_bridge.py x142sb_ing1 ACD-14.2-brmsSDImax
python3 04_collate_bridge.py prod_fix_ing1_c100 ACD-prod-12.5.2-c100
python3 04_collate_bridge.py x142sb_ing1_c100 ACD-14.2-brmsSDImax-c100
for r in prod_fix_ing1 x142sb_ing1 prod_fix_ing1_c100 x142sb_ing1_c100 prod_fix_ing0 x142sb_ing0; do
  echo "$r done $(ls $R/batch/$r/b*/P*/DONE 2>/dev/null | wc -l) keys $(ls $R/batch/$r/b*/*.key 2>/dev/null | wc -l) rtn: $(cat $R/batch/$r/b*/P*/DONE 2>/dev/null | awk '{print $2}' | sort | uniq -c | tr '\n' ' ')"; cut -d, -f3 $R/results/${r}_errors.csv 2>/dev/null | sort | uniq -c | head -5; done
ls -la --time-style=+%m-%d_%H:%M $R/research/results | cut -c30-
echo POST1_DONE
