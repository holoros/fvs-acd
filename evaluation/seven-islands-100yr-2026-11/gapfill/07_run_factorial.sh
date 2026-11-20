#!/bin/bash
# Stress test 2 x 2 on every 9th plot (59 plots): which part of the 14.2 arm drives the basal area rise.
# usage: 07_run_factorial.sh RUN ARMDIR(prod_fix|x142sb) USE_X142(0|1) USE_SDIB(0|1) ; ingrowth on, 5-year cycles
RUN=$1; AD=$2; UX=$3; US=$4
R=~/restricted/silc_agmbench_gapfill_20261117; J=~/jobs/silc_agmbench_100yr_20261117; A=~/fvsacd142/state/work/arms
B=$R/batch/$RUN/b0; mkdir -p $B; i=0
for k in $(ls $R/keys/c5/*.key | sort); do [ $((i % 9)) -eq 0 ] && cp -n $k $B/; i=$((i+1)); done
export V_ARM=$( [ $AD = x142sb ] && echo x142sb || echo prod_fix ) V_ARMDIR=$A/$AD V_CAPTURE= V_MAXRUNS=300 SILC_INGROWTH=Yes
unset V_X142 V_SDIB V_X142_FOLDMAP V_X142_CUT
[ $UX = 1 ] && export V_X142=~/fvsacd142/state/work/x142/x142_gseq.csv
[ $US = 1 ] && export V_SDIB=$R/silc_sdib.csv
echo "start $RUN $(ls $B/*.key | wc -l) keys $(date -Iseconds)"
Rscript $J/bridge_silc.R $B >> $R/batch/$RUN/b0.rout 2>&1
echo "end $RUN done $(ls $B/P*/DONE | wc -l) $(date -Iseconds)"
