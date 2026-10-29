#!/bin/bash
# PREREG50 launcher (copy of PREREG45 launch_p45.sh with the driver name and log names changed): runs the tasks listed in a
# task id file, at most 2 at once (the shared host cap), and holds each launch while the 1 minute load average is 12 or
# above. Task logs carry stand names, so they are named _SERVERONLY. Usage: HOME=<bundle home> bash launch_p50.sh <ids> <tag>
# No em dashes.
IDS=$1; TAGS=$2; cd $HOME; mkdir -p logs
for t in $(cat $IDS); do
  while :; do
    n=$(pgrep -f "run_task_p50.sh" | wc -l); l=$(awk '{print $1}' /proc/loadavg)
    if [ "$n" -lt 2 ] && awk -v l="$l" 'BEGIN{exit !(l<12)}'; then break; fi
    sleep 20
  done
  ( bash $HOME/../scripts/run_task_p50.sh $t > logs/task_${t}_SERVERONLY.log 2>&1; echo "task $t exit $? $(date -Is)" >> logs/_status_${TAGS}.txt ) &
  sleep 5
done
wait; echo ALL_DONE >> logs/_status_${TAGS}.txt
