#!/bin/bash
# PREREG20: all tasks in taskmap order, at most 4 at once (sibling tracks share firebreather), and no task starts while the
# 1 minute load average is above 14. One log per task. Usage: HOME=<bundle home> bash launch_p20.sh
cd $HOME; mkdir -p logs
gate() { while awk '{exit !($1 > 14)}' /proc/loadavg; do sleep 60; done; }
export -f gate
seq 1 $(($(wc -l < work/p20_taskmap_DATA_2026-09-28.csv) - 1)) | xargs -P 4 -I{} bash -c 'gate; echo "task {} start $(date -Is) load $(cut -d" " -f1 /proc/loadavg)" >> logs/_launch.txt; bash run_task_p20.sh {} > logs/task_{}.log 2>&1; echo "task {} exit $?" >> logs/_status.txt'
echo ALL_DONE >> logs/_status.txt
