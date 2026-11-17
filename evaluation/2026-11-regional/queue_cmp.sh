#!/bin/bash
# PREREG_GY2 Amendment 3: comparator arms (no R), two workers, nice 10; scoring and Bakuzis wait for OPT_DONE (keeps R <= 2).
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1
J=~/jobs/gy2eval_20261112; B=~/fvsacd142/state/restricted/batch
cr(){ [ -f $B/$3/meta.json ] && { echo "skip $3"; return; }; echo "start $3 $(date -Iseconds)"; nice -n 10 python3 $J/cmp_run.py --set $1 --arm $2 --run $3 --workers 2 > $J/out/cmp_$3.log 2>&1; echo "end $3 rc=$? $(tail -c 300 $J/out/cmp_$3.log | tr -d '\n') $(date -Iseconds)"; }
for a in "fvs_base fb" "fvs_regional fr" "conus_spdep cs" "osm os"; do set -- $a; cr bakz $1 bk$2; done
for s in gy2 gy2L; do for a in "fvs_base fb" "fvs_regional fr" "conus_spdep cs" "osm os"; do set -- $a; cr $s $1 cm$2_$s; done; done
for a in "fvs_base fb" "fvs_regional fr" "conus_spdep cs" "osm os"; do set -- $a; cr t14H $1 t14H_cm$2; done
echo CMP_RUNS_DONE
until grep -q OPT_DONE $J/queue_opt.log 2>/dev/null; do sleep 120; done; echo "opt done seen $(date -Iseconds)"
vs(){ echo "vol $4 $(date -Iseconds)"; nice -n 10 python3 $J/vol_score.py "$@" > $J/out/vol_$4.log 2>&1; echo rc=$?; }
vs gy2 gyp_gy2 gyx_gy2,gyxG_gy2,gycsi_gy2,gya7c_gy2,gya7xH_gy2,gya7xSIH_gy2,cmfb_gy2,cmfr_gy2,cmcs_gy2,cmos_gy2 gy2_cmp
vs gy2L gyp_gy2L gyx_gy2L,gyxG_gy2L,gya7c_gy2L,gya7x_gy2L,gya7xSI_gy2L,cmfb_gy2L,cmfr_gy2L,cmcs_gy2L,cmos_gy2L gy2L_cmp
vs g2 t14H_prod_fix t14H_x142GS,t14H_x142G,t14H_prodcsi,t14H_acd7c,t14H_acd7x,t14H_acd7xSI,t14H_cmfb,t14H_cmfr,t14H_cmcs,t14H_cmos t14H_cmp
cd $J && nice -n 10 python3 bakz_traj.py bkfb,bkfr,bkcs,bkos >> bakz/traj.log 2>&1; echo "traj rc=$?"
for r in bkfb bkfr bkcs bkos; do
  nice -n 10 Rscript ~/jobs/acd_bakuzis/bakuzis_check_step-aware_FINAL_2026-09-07.R bakz/traj_$r.csv 0.40 0.10 > bakz/check_$r.txt 2>&1
  nice -n 10 Rscript ~/jobs/fvsacd_bakuzis/bakuzis_matrix.R bakz/traj_$r.csv bakz/matrix_$r.png > bakz/mat_$r.log 2>&1; echo "bakuzis $r rc=$?"; done
echo CMP_DONE $(date -Iseconds)
