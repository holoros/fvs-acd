#!/bin/bash
# PREREG31: builds the long horizon driver from the frozen PREREG28b runner and records the diff. Refuses to overwrite.
# The QC dht.mult expression is cut from runner line 425 (between "dht.mult=" and ",mort.mult=1") and put in place of the
# @@DHT@@ placeholder, with it$DBH as the runner's own variable name (the block passes the tree list as 'it').
set -euo pipefail; S=/home/aaron/jobs/v142p31/scripts; R=/home/aaron/jobs/v142p28b/home/runner_p28_fb.R; D=$S/driver_p31.R
[ "$(md5sum $R | cut -d' ' -f1)" = 0a2b27421ee7b25eaab7f4591ce3af97 ] || { echo "runner md5 mismatch"; exit 4; }
[ ! -e $D ] || { echo "REFUSE $D exists"; exit 3; }
X=$(sed -n 425p $R | sed 's/^.*,dht\.mult=\(.*\),mort\.mult=1,max\.dbh=200.*$/\1/')
[ "$(sed -n 425p $R | grep -o 'dht\.mult=' | wc -l)" = 1 ] || { echo "line 425 not as expected"; exit 5; }
printf '%s\n' "$X" > $S/parts/dht_expr_line425.txt
{ cat $S/parts/head.txt; head -n 419 $R; awk -v x="$X" '{ if (index($0, "@@DHT@@")) { i = index($0, "@@DHT@@"); print substr($0, 1, i-1) x substr($0, i+7) } else print }' $S/parts/p31_block.R; } > $D
grep -q '@@DHT@@' $D && { echo "placeholder left"; exit 6; }
diff -u $R $D > /home/aaron/jobs/v142p31/diffs/runner_p28_fb.R_to_driver_p31.R.diff || true
cmp <(head -n 426 $D | tail -n 419) <(head -n 419 $R) && echo "lines 1 to 419 byte identical"
md5sum $D
