#!/bin/bash
# PREREG33 launcher (copy of PREREG28b launch_p28b.sh; driver name only). PREREG28b launcher (copy of PREREG28 launch_p28.sh md5 51f3c1f7). PREREG28 launcher (copy of PREREG23 launch_p23.sh, itself a copy of PREREG19 launch_p19.sh md5 25786453): runs the tasks listed in a task id file, at most 2 at once (the shared host cap), and holds each launch
# while the 1 minute load average is above 12 (this track cap). Usage: HOME=<bundle home> bash launch_p19.sh <taskids file> <status tag>
IDS=$1; TAGS=$2; cd $HOME; mkdir -p logs
for t in $(cat $IDS); do
  while :; do
    n=$(pgrep -f "run_task_p33.sh" | wc -l); l=$(awk '{print $1}' /proc/loadavg)
    if [ "$n" -lt 2 ] && awk -v l="$l" 'BEGIN{exit !(l<12)}'; then break; fi
    sleep 20
  done
  ( bash $HOME/../scripts/run_task_p33.sh $t > logs/task_${t}.log 2>&1; echo "task $t exit $?" >> logs/_status_${TAGS}.txt ) &
  sleep 5
done
wait; echo ALL_DONE >> logs/_status_${TAGS}.txt
