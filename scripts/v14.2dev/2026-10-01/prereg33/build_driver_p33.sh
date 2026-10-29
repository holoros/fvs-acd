#!/bin/bash
# PREREG33: builds the long horizon driver from runner_p33_fb.R by the PREREG31 method and records the diffs. Refuses to overwrite.
set -euo pipefail; S=/home/aaron/jobs/v142p33/scripts; R=/home/aaron/jobs/v142p33/home/runner_p33_fb.R; D=$S/driver_p33.R
[ "$(md5sum $R | cut -d' ' -f1)" = e3301b780599bc23aaf2d7bd41836b93 ] || { echo "runner md5 mismatch"; exit 4; }
[ ! -e $D ] || { echo "REFUSE $D exists"; exit 3; }
[ "$(grep -n '^for(k in seq_len(nrow(prs)))' $R | cut -d: -f1)" = 434 ] || { echo "loop not at line 434"; exit 5; }
[ "$(sed -n 439p $R | grep -o 'dht\.mult=' | wc -l)" = 1 ] || { echo "line 439 not as expected"; exit 5; }
X=$(sed -n 439p $R | sed 's/^.*,dht\.mult=\(.*\),mort\.mult=1,max\.dbh=200.*$/\1/')
printf '%s\n' "$X" > $S/parts/dht_expr_line439.txt
cmp $S/parts/dht_expr_line439.txt /home/aaron/jobs/v142p31/scripts/parts/dht_expr_line425.txt && echo "dht expression identical to PREREG31"
{ cat $S/parts/head.txt; head -n 433 $R; awk -v x="$X" '{ if (index($0, "@@DHT@@")) { i = index($0, "@@DHT@@"); print substr($0, 1, i-1) x substr($0, i+7) } else print }' $S/parts/p33_block.R; } > $D
grep -q '@@DHT@@' $D && { echo "placeholder left"; exit 6; }
diff -u $R $D > /home/aaron/jobs/v142p33/diffs/runner_p33_fb.R_to_driver_p33.R.diff || true
diff -u /home/aaron/jobs/v142p31/scripts/driver_p31.R $D > /home/aaron/jobs/v142p33/diffs/driver_p31.R_to_driver_p33.R.diff || true
diff -u /home/aaron/jobs/v142p31/scripts/parts/p31_block.R $S/parts/p33_block.R > /home/aaron/jobs/v142p33/diffs/p31_block.R_to_p33_block.R.diff || true
NH=$(wc -l < $S/parts/head.txt); cmp <(head -n $((NH+433)) $D | tail -n 433) <(head -n 433 $R) && echo "lines 1 to 433 byte identical"
md5sum $D
