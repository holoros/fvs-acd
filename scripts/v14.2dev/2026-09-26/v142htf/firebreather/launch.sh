#!/bin/bash
# Run all tasks, 8 in parallel, one log per task. Usage: HOME=<bundle home> bash launch.sh
cd $HOME; mkdir -p logs
seq 1 $(($(wc -l < work/htfix_taskmap_DATA_2026-09-26.csv) - 1)) | xargs -P 8 -I{} bash -c 'bash run_task.sh {} > logs/task_{}.log 2>&1; echo "task {} exit $?" >> logs/_status.txt'
echo ALL_DONE >> logs/_status.txt
