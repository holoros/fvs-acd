#!/bin/bash
# PREREG22 chain. Waits (sleep 300) for CHAIN_DONE in ~/jobs/v142p18/logs_chain.txt (read only for that line; stops if the
# PREREG18 chain pid 1115055 is gone without it), extracts m* (p22_mstar.sh), writes the taskmap, launches (launch_p22.sh:
# at most 2 tasks at once, none while the 1 minute load is above 14), retries time limited stands by STAND name for every
# column, then G0 and the Maine control, scoring, H2 and assembly. Each step logs to logs_chain.txt and its own log; the
# chain stops at the first failure; nothing is overwritten. No coordinates. No em dashes.
J=/home/aaron/jobs/v142p22; H=$J/home; LOG=$J/logs_chain.txt; P18=/home/aaron/jobs/v142p18; P18PID=1115055
TM=$H/work/p22_taskmap_DATA_2026-09-29.csv; SRC=/home/aaron/jobs/v142p20/home/work/p20_taskmap_DATA_2026-09-28.csv
step() { local n=$1; shift; "$@"; local rc=$?; echo "$n exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || { echo "CHAIN_STOP at $n (exit $rc) $(date -Is)" >> $LOG; exit $rc; }; }
cd $J; echo "chain start $(date -Is) pid=$$" >> $LOG
until grep -q CHAIN_DONE $P18/logs_chain.txt 2>/dev/null; do
  if ! kill -0 $P18PID 2>/dev/null; then sleep 60
    grep -q CHAIN_DONE $P18/logs_chain.txt 2>/dev/null || { echo "CHAIN_STOP: PREREG18 chain pid $P18PID ended without CHAIN_DONE; no m*; PREREG22 does not launch $(date -Is)" >> $LOG; exit 20; }
  else sleep 300; fi
done
echo "PREREG18 CHAIN_DONE seen $(date -Is)" >> $LOG
step mstar bash -c "bash $J/scripts/p22_mstar.sh > $J/logs_mstar.txt 2>&1"
grep -E '^P22_IMULT=|^P18_RULE=' $J/plan/mstar.env >> $LOG
step taskmap bash -c "[ ! -e $TM ] && awk -F, 'BEGIN{OFS=\",\"} NR==1{print; next} {if (\$2==\"v141LTf\") \$2=\"v141LTfi\"; print}' $SRC > $TM && [ \$(awk -F, 'NR>1 && \$2==\"v141LTfi\"' $TM | wc -l) -eq 36 ] && md5sum $TM"
while awk '{exit !($1 > 14)}' /proc/loadavg; do sleep 60; done
step launch bash -c "HOME=$H bash $H/launch_p22.sh > $J/logs_launch.txt 2>&1 && grep -q ALL_DONE $H/logs/_status.txt && ! grep -q 'exit [1-9]' $H/logs/_status.txt"
for c in g0_off ctl_memat v141LTfi; do step retry_$c bash -c "HOME=$H bash $H/retry_timeouts_p22.sh $c"; echo "retry $c: $(tail -1 $H/logs/retry_$c.log)" >> $LOG; done
step g0ctl bash -c "Rscript $J/scripts/2026-09-29_v142_p22_g0ctl.R > $J/logs_g0ctl.txt 2>&1"
step score bash -c "bash $J/scripts/run_score_p22.sh > $J/logs_score.txt 2>&1"
step h2 bash -c "Rscript $J/scripts/2026-09-29_v142_p22_h2.R > $J/logs_h2.txt 2>&1"
step assemble bash -c "Rscript $J/scripts/2026-09-29_v142_p22_assemble.R > $J/logs_assemble.txt 2>&1"
echo "CHAIN_DONE $(date -Is)" >> $LOG
