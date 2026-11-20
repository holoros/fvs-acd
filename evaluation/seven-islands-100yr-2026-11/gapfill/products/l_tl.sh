#!/bin/bash
cd ~/jobs/silc_agmbench_100yr_20261117/products
~/bin/fbq run -t 1 -n silc_prod_bridge_tl -- python3 20_collect_bridge_tl.py > s20.log 2>&1 &
~/bin/fbq run -t 2 -n silc_prod_ne_tl -- python3 19_native_tl.py fvs_ne 2 > s19_ne.log 2>&1
wait
