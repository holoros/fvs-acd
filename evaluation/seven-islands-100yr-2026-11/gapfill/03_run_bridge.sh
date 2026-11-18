#!/bin/bash
# One bridge worker. usage: 03_run_bridge.sh RUN ARM INGROWTH(Yes|No) KEYSET(c5|c100) SHARD NSHARD [LIMIT]
# RUN = batch name under RESTRICTED/batch. ARM = prod_fix (AcadianGY 12.5.2, PR 28) or x142sb (12.5.2 + brms SDImax + 14.2 multipliers).
set -u
RUN=$1; ARM=$2; ING=$3; KS=$4; SH=$5; NS=$6; LIM=${7:-0}
R=~/restricted/silc_agmbench_gapfill_20261117; J=~/jobs/silc_agmbench_100yr_20261117; A=~/fvsacd142/state/work/arms
B=$R/batch/$RUN/b$SH; mkdir -p $B
i=0; n=0
for k in $(ls $R/keys/$KS/*.key | sort); do
  if [ $((i % NS)) -eq $SH ]; then [ "$LIM" -gt 0 ] && [ $n -ge "$LIM" ] && break; cp -n $k $B/; n=$((n+1)); fi; i=$((i+1))
done
export V_ARM=$ARM V_ARMDIR=$A/$ARM V_CAPTURE= V_MAXRUNS=300 SILC_INGROWTH=$ING
unset V_X142 V_SDIB V_X142_FOLDMAP V_X142_CUT
if [ "$ARM" = x142sb ]; then export V_X142=~/fvsacd142/state/work/x142/x142_gseq.csv V_SDIB=$R/silc_sdib.csv; fi
undone(){ c=0; for k in $B/*.key; do [ -f ${k%.key}/DONE ] || c=$((c+1)); done; echo $c; }
left=$(undone); echo "start $RUN b$SH keys $n undone $left $(date -Iseconds)"
while [ "$left" -gt 0 ]; do
  Rscript $J/bridge_silc.R $B >> $R/batch/$RUN/b$SH.rout 2>&1
  now=$(undone); [ "$now" -ge "$left" ] && break; left=$now
done
echo "end $RUN b$SH undone $(undone) $(date -Iseconds)"
