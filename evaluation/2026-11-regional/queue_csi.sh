#!/bin/bash
# Production 12.5.1 with ESI passed directly as the Event Monitor CSI (no code change), on gy2 and T14 H, after the T14 H queue.
while kill -0 4028127 2>/dev/null; do sleep 60; done; echo "t14H queue ended $(date -Iseconds)"
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1
F=~/fvsacd142; S=$F/state; J=~/jobs/gy2eval_20261112
echo "start gycsi_gy2 $(date -Iseconds)"
V_CSI_DIRECT=1 nice -n 10 python3 $F/tools/v26_V/v_batch.py --set gy2 --arm prod_fix --out $S/restricted/runs/gycsi_gy2 --batch $S/restricted/batch/gycsi_gy2 --workers 2 > $S/logs/gycsi_gy2.log 2>&1; echo "rc=$?"
nice -n 10 python3 $F/tools/reg_score.py --set gy2 --base gyp_gy2 --cand gycsi_gy2,gyx_gy2,gya7x_gy2,gya7xSI_gy2 --tag gy2_csi > $J/score_gy2_csi.log 2>&1; echo "score rc=$?"
echo "start t14H_prodcsi $(date -Iseconds)"
V_CSI_DIRECT=1 nice -n 10 python3 $F/tools/t14/v_batch.py --set g2 --arm prod_fix --out $S/restricted/runs/t14H_prodcsi --batch $S/restricted/batch/t14H_prodcsi --workers 2 --ids $S/restricted/sub/g2H_ids.txt > $S/logs/t14H_prodcsi.log 2>&1; echo "rc=$?"
nice -n 10 python3 $F/tools/t14/t14_score.py --set g2 --base t14H_prod_fix --cand t14H_prodcsi,t14H_x142GS,t14H_acd7x,t14H_acd7xSI --tag t14H_csi > $J/score_t14H_csi.log 2>&1; echo "score rc=$?"
echo CSI_DONE
