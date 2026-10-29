#!/bin/bash
# Searcher B scan per PREREG43 search set item 1. Read-only.
OUT=~/jobs/v142p43/search_b
cd ~
: > $OUT/raw_hits_B.txt
: > $OUT/filelist_B.txt
for ROOT in jobs repos-mirror src output; do
  find "$ROOT" \
    \( -path 'jobs/v142p38' -o -path 'jobs/v142p39' -o -path 'jobs/v142p40' -o -path 'jobs/v142p41' -o -path 'jobs/v142p42' -o -path 'jobs/v142p43' \
       -o -name '*gh_v142*' -o -name '*_laptop*' -o -name '*_PREV_*' \) -prune -o \
    -type f -size -5121k \( -name '*.r' -o -name '*.R' -o -name '*.md' -o -name '*.txt' -o -name '*.csv' -o -name '*.json' -o -name '*.sh' -o -name '*.py' -o -name '*.log' \) -print 2>>$OUT/scan_errors_B.log >> $OUT/filelist_B.txt
done
echo "files: $(wc -l < $OUT/filelist_B.txt)" > $OUT/scan_B.log
tr '\n' '\0' < $OUT/filelist_B.txt | xargs -0 grep -n -H -F -e '0.111' -e 'QC_AFAC' -e 'dht.mult' 2>>$OUT/scan_errors_B.log >> $OUT/raw_hits_B.txt
echo "raw hit lines: $(wc -l < $OUT/raw_hits_B.txt)" >> $OUT/scan_B.log
echo DONE >> $OUT/scan_B.log
