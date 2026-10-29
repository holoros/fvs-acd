#!/bin/bash
# PREREG18 launcher: the 72 tasks of work/p18_taskmap in taskmap order, at most MAXJ (4) of this track's tasks at once, and
# a new task starts only when the 1 minute load average is at or below LMAX (14); firebreather is shared with sibling
# tracks. Resume safe: run_task_p18.sh refuses (exit 3) a task whose results file exists, so a relaunch skips finished
# tasks; START_AT skips earlier task numbers. Usage: HOME=<bundle home> bash launch_p18.sh. No coordinates. No em dashes.
cd $HOME; mkdir -p logs
TM=work/p18_taskmap_DATA_2026-09-28.csv; N=$(($(wc -l < $TM) - 1)); MAXJ=${MAXJ:-4}; LMAX=${LMAX:-14}; t=${START_AT:-1}
echo "launcher start $(date -Is) N=$N MAXJ=$MAXJ LMAX=$LMAX from=$t pid=$$" >> logs/_launch.txt
lasthold=0
while [ $t -le $N ] || [ $(jobs -rp | wc -l) -gt 0 ]; do
  if [ $t -le $N ] && [ $(jobs -rp | wc -l) -lt $MAXJ ]; then
    l=$(cut -d' ' -f1 /proc/loadavg)
    if awk -v l=$l -v m=$LMAX 'BEGIN{exit !(l <= m)}'; then
      ( bash run_task_p18.sh $t > logs/task_$t.log 2>&1; echo "task $t exit $? $(date -Is)" >> logs/_status.txt ) &
      echo "launch task $t load $l running $(($(jobs -rp | wc -l))) $(date -Is)" >> logs/_launch.txt
      t=$((t + 1)); sleep 30; continue
    fi
    now=$(date +%s); if [ $((now - lasthold)) -ge 900 ]; then echo "hold next task $t: load $l above $LMAX $(date -Is)" >> logs/_launch.txt; lasthold=$now; fi
  fi
  sleep 60
done
echo "ALL_DONE $(date -Is)" >> logs/_status.txt
