#!/bin/bash
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1; cd ~/jobs/silc_agmbench_100yr_20261117
nice -n 10 python3 05_aggregate.py && nice -n 10 Rscript 06_figures.R; echo POST2_DONE; ls -la agg
