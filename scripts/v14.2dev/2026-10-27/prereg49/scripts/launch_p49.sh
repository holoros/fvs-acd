#!/bin/bash
# PREREG49 launcher (PREREG45 launch_p45.sh, md5 ca663344, with the task driver path and name only). Runs the tasks listed in a
# task id file, at most 2 at once, and holds each launch while the 1 minute load average is 12 or above.
# Usage: HOME=<ROOT>/home bash launch_p49.sh <taskids file> <status tag>. No em dashes.
IDS=$1; TAGS=$2; J=${P49_ROOT:-/home/aaron/jobs/v142p49}; cd $HOME; mkdir -p logs
for t in $(cat $IDS); do
  while :; do
    n=$(pgrep -f "run_task_p49.sh" | wc -l); l=$(awk '{print $1}' /proc/loadavg)
    if [ "$n" -lt 2 ] && awk -v l="$l" 'BEGIN{exit !(l<12)}'; then break; fi
    sleep 20
  done
  ( bash $J/scripts/run_task_p49.sh $t > logs/task_${t}.log 2>&1; echo "task $t exit $?" >> logs/_status_${TAGS}.txt ) &
  sleep 5
done
wait; echo ALL_DONE >> logs/_status_${TAGS}.txt
