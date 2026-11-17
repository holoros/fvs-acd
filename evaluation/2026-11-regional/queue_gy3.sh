#!/bin/bash
# PREREG_GY2 Amendment 4: gy3 and gy3L (programs added 14 and 15 Nov 2026). Waits for gydb2 q19. R work under the shared lock, nice 10.
until grep -q "^combine" ~/gydb2/work/q19.log 2>/dev/null; do sleep 120; done; echo "q19 combine seen (gy3 does not need the layers) $(date -Iseconds)"
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1
F=~/fvsacd142; S=$F/state; T=$F/tools/v26_V; W=$S/work/x142; J=~/jobs/gy2eval_20261112; A=~/jobs/acd7_port; B=$S/restricted/batch; L=~/gydb2/staging/r.lock
cd $J; [ -f gy3_cap.json ] || { echo "STOP: run gy3_build.py then gy3_cap.py first"; exit 1; }; echo "using capped sets (Amendment 4a)"
vb(){ [ -f $S/restricted/runs/$3/pair_rows.csv ] && { echo "skip $3"; return; }
  echo "start $3 $(date -Iseconds)"
  flock $L nice -n 10 python3 $T/v_batch.py --set $1 --arm $2 --out $S/restricted/runs/$3 --batch $S/restricted/batch/$3 --workers 2 > $S/logs/$3.log 2>&1
  echo "end $3 rc=$? $(date -Iseconds)"; }
a7(){ echo "acd7 $3 $(date -Iseconds)"
  flock $L bash -c "( nice -n 10 Rscript $A/repo6/tests/acd7_arm.R $1 $2 $3 $4 $5 $A/repo6 1 2 > $J/$3_l1.log 2>&1 ) & ( nice -n 10 Rscript $A/repo6/tests/acd7_arm.R $1 $2 $3 $4 $5 $A/repo6 2 2 > $J/$3_l2.log 2>&1 ) & wait"
  echo "acd7 end $3 $(date -Iseconds)"; }
cr(){ [ -f $B/$3/meta.json ] && { echo "skip $3"; return; }; echo "start $3 $(date -Iseconds)"; nice -n 10 python3 $J/cmp_run.py --set $1 --arm $2 --run $3 --workers 2 > $J/out/cmp_$3.log 2>&1; echo "end $3 rc=$? $(date -Iseconds)"; }
sc(){ echo "score $*"; nice -n 10 python3 $F/tools/reg_score.py "$@" > $J/score_$(echo "$@" | sed 's/.*--tag //;s/ .*//').log 2>&1; echo rc=$?; }
vs(){ echo "vol $4 $(date -Iseconds)"; nice -n 10 python3 $J/vol_score.py "$@" > $J/out/vol_$4.log 2>&1; echo rc=$?; }
for s in gy3 gy3L; do
  vb $s prod_fix gyp_${s}
  V_X142=$W/x142_gseq.csv vb $s x142 gyx_${s}
  a7 $s gyp_${s} gya7c_${s} compiled prod
  a7 $s gyp_${s} gya7x_${s} corrected prod
  a7 $s gyp_${s} gya7xSI_${s} corrected si
  for a in "fvs_base fb" "fvs_regional fr" "conus_spdep cs"; do set -- $a; cr $s $1 cm$2_$s; done
  C=gyx_${s},gya7c_${s},gya7x_${s},gya7xSI_${s}          # reg_score reads bridge output only; comparator arms are scored by vol_score
  sc --set $s --base gyp_${s} --cand $C --tag ${s}_main
  sc --set $s --base gyp_${s} --cand $C --tag ${s}_main_shuf7 --shuffle-seed 7
  vs $s gyp_${s} $C,cmfb_${s},cmfr_${s},cmcs_${s} ${s}_cmp
done
echo GY3_DONE $(date -Iseconds)
