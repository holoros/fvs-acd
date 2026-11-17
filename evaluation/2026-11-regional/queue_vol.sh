#!/bin/bash
# Volume, biomass and SDI scoring plus Bakuzis projections (Aaron 14:29). After the CSI queue; q14 waits for this queue.
while pgrep -f '[q]ueue_csi.sh' > /dev/null; do sleep 60; done; echo "csi queue ended $(date -Iseconds)"
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1
F=~/fvsacd142; S=$F/state; T=$F/tools/v26_V; W=$S/work/x142; J=~/jobs/gy2eval_20261112; A=~/jobs/acd7_port
vb(){ [ -f $S/restricted/runs/$3/pair_rows.csv ] && { echo "skip $3"; return; }
  echo "start $3 $(date -Iseconds)"
  nice -n 10 python3 $T/v_batch.py --set $1 --arm $2 --out $S/restricted/runs/$3 --batch $S/restricted/batch/$3 --workers 2 > $S/logs/$3.log 2>&1
  echo "end $3 rc=$? $(date -Iseconds)"; }
a7(){ echo "acd7 $3 $(date -Iseconds)"
  ( nice -n 10 Rscript $A/repo6/tests/acd7_arm.R $1 $2 $3 $4 $5 $A/repo6 1 2 > $J/$3_l1.log 2>&1 ) &
  ( nice -n 10 Rscript $A/repo6/tests/acd7_arm.R $1 $2 $3 $4 $5 $A/repo6 2 2 > $J/$3_l2.log 2>&1 ) & wait; echo "acd7 end $3 $(date -Iseconds)"; }
vs(){ echo "vol $*"; nice -n 10 python3 $J/vol_score.py "$@" > $J/out/vol_$4.log 2>&1; echo rc=$?; }
a7 gy2 gyp_gy2 gya7xH_gy2 corrected prod
a7 gy2 gyp_gy2 gya7xSIH_gy2 corrected si
a7 reg r0e_reg_prod_fix acd7xH_reg corrected prod
vs gy2 gyp_gy2 gyx_gy2,gycsi_gy2,gya7xH_gy2,gya7xSIH_gy2 gy2
vs gy2L gyp_gy2L gyx_gy2L,gya7x_gy2L,gya7xSI_gy2L gy2L
vs g2 t14H_prod_fix t14H_x142GS,t14H_prodcsi,t14H_acd7x,t14H_acd7xSI t14H
vs reg r0e_reg_prod_fix x142fullGS_reg,acd7xH_reg reg
vb bakz prod_fix bkp
V_CSI_DIRECT=1 vb bakz prod_fix bkpcsi
V_X142=$W/x142_gseq.csv vb bakz x142 bkx
V_X142=$W/x142_gseq.csv V_CSI_DIRECT=1 vb bakz x142 bkxcsi
a7 bakz bkp bka7x corrected prod
a7 bakz bkp bka7xSI corrected si
echo VOL_DONE
