#!/bin/bash
# Bridge arms on the Bakuzis stands x site levels. Ingrowth cut point 0, 5 cm minimum (the working-ingrowth setting).
# usage: 12_run_bakz_bridge.sh RUN ARM TREEMORT(0|1) LREF CAP(0|1) SHARD NSHARD
set -u
RUN=$1; ARM=$2; TM=$3; LREF=$4; CAP=$5; SH=$6; NS=$7
R=~/restricted/silc_agmbench_gapfill_20261117; J=~/jobs/silc_agmbench_100yr_20261117; A=~/fvsacd142/state/work/arms
B=$R/bakz/batch/$RUN/b$SH; mkdir -p $B; i=0
for k in $(ls $R/bakz/keys/*.key | sort); do [ $((i % NS)) -eq $SH ] && cp -n $k $B/; i=$((i+1)); done
export SILC_INGROWTH=Yes SILC_MINDBH=1.9685 SILC_CUT=0 V_ARM=$ARM V_ARMDIR=$A/$ARM V_CAPTURE= V_MAXRUNS=300
unset V_X142 V_SDIB V_ECO V_X142_FOLDMAP V_X142_CUT V_TREEMORT V_LREF V_SDICAP
if [ "$ARM" != prod_fix ]; then export V_X142=~/fvsacd142/state/work/x142/x142_gseq.csv V_SDIB=$R/bakz/sdib.csv V_ECO=$R/bakz/eco.csv; fi
[ "$TM" = 1 ] && export V_TREEMORT=1 V_LREF=$LREF
[ "$CAP" = 1 ] && export V_SDICAP=1
undone(){ c=0; for k in $B/*.key; do [ -f ${k%.key}/DONE ] || c=$((c+1)); done; echo $c; }
left=$(undone); echo "start $RUN b$SH undone $left $(date -Iseconds)"
while [ "$left" -gt 0 ]; do
  Rscript $J/bridge_silc3.R $B >> $R/bakz/batch/$RUN/b$SH.rout 2>&1
  now=$(undone); [ "$now" -ge "$left" ] && break; left=$now
done
echo "end $RUN b$SH undone $(undone) $(date -Iseconds)"
