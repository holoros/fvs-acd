#!/bin/bash
cd ~/perseus_me && source run/env.sh >/dev/null 2>&1; cd ~/jobs/silc_agmbench_100yr_20261117
python3 04_collate_bridge.py prod_fix_ingT0 ACD-prod-ingT0
python3 04_collate_bridge.py x142sb_ingT0 ACD-142sb-ingT0
python3 04_collate_bridge.py fact_mult_only ACD-mult-only | head -1
python3 04_collate_bridge.py fact_sdib_only ACD-sdib-only | head -1
echo POST5_DONE
