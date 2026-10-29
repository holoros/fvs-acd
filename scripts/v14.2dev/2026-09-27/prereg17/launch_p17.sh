#!/bin/bash
# PREREG17: all tasks, 8 at a time (the firebreather 8 core cap), one log per task, in taskmap order. Usage: HOME=<bundle home> bash launch_p17.sh
cd $HOME; mkdir -p logs
seq 1 $(($(wc -l < work/p17_taskmap_DATA_2026-09-27.csv) - 1)) | xargs -P 8 -I{} bash -c 'bash run_task_p17.sh {} > logs/task_{}.log 2>&1; echo "task {} exit $?" >> logs/_status.txt'
echo ALL_DONE >> logs/_status.txt
