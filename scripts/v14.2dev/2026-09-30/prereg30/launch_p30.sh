#!/bin/bash
# PREREG30: all tasks of work/p30_taskmap in order, at most 2 R model processes at once, no task started while the 1 minute
# load average is 12 or above; then by name retries of host time limit stands (up to three attempts, same gate, one at a
# time). One log per task. Usage: HOME=/home/aaron/jobs/v142p30/home setsid nohup bash launch_p30.sh > logs/nohup.txt 2>&1 &
cd $HOME; mkdir -p logs tables
gate() { while awk '{exit !($1 >= 12)}' /proc/loadavg; do sleep 60; done; }
export -f gate
echo "launch $(date -Is)" >> logs/_launch.txt
seq 1 $(($(wc -l < work/p30_taskmap_DATA_2026-09-30.csv) - 1)) | xargs -P 2 -I{} bash -c 'gate; echo "task {} start $(date -Is) load $(cut -d" " -f1 /proc/loadavg)" >> logs/_launch.txt; bash run_task_p30.sh {} > logs/task_{}.log 2>&1; echo "task {} exit $?" >> logs/_status.txt'
echo MAIN_DONE >> logs/_status.txt
bash retry_timeouts_p30.sh g0_off; echo "retry done: $(tail -1 logs/retry_g0_off.log)" >> logs/_status.txt
echo ALL_DONE >> logs/_status.txt
