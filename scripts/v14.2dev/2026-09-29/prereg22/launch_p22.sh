#!/bin/bash
# PREREG22: all tasks in taskmap order, at most 2 at once (three sibling tracks share firebreather), and no task starts while
# the 1 minute load average is above 14. One log per task. Copy of ~/jobs/v142p20/home/launch_p20.sh with -P 2 and the
# p22 names. Usage: HOME=<bundle home> bash launch_p22.sh
cd $HOME; mkdir -p logs
gate() { while awk '{exit !($1 > 14)}' /proc/loadavg; do sleep 60; done; }
export -f gate
seq 1 $(($(wc -l < work/p22_taskmap_DATA_2026-09-29.csv) - 1)) | xargs -P 2 -I{} bash -c 'gate; echo "task {} start $(date -Is) load $(cut -d" " -f1 /proc/loadavg)" >> logs/_launch.txt; bash run_task_p22.sh {} > logs/task_{}.log 2>&1; echo "task {} exit $?" >> logs/_status.txt'
echo ALL_DONE >> logs/_status.txt
