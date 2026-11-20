#!/bin/bash
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1; cd ~/jobs/silc_agmbench_100yr_20261117
nice -n 5 python3 15_final_aggregate.py && nice -n 5 Rscript 16_final_figures.R; echo POST7_DONE
