#!/bin/bash
# PREREG43 searcher A scan: list candidate files then grep three literals (fixed string, case sensitive)
OUT=~/jobs/v142p43/search_a
: > $OUT/files.txt
for R in ~/jobs ~/repos-mirror ~/src ~/output; do
  find "$R" -type f -size -5242881c \( -name '*.r' -o -name '*.R' -o -name '*.md' -o -name '*.txt' -o -name '*.csv' -o -name '*.json' -o -name '*.sh' -o -name '*.py' -o -name '*.log' \) \
   -not -path '*/v142p38/*' -not -path '*/v142p39/*' -not -path '*/v142p40/*' -not -path '*/v142p41/*' -not -path '*/v142p42/*' -not -path '*/v142p43/*' \
   -not -path '*/gh_v142*' -not -path '*_laptop*' -not -path '*_PREV_*' -print0 2>>$OUT/find_err.log >> $OUT/files.txt
done
echo "files_done $(tr -cd '\0' < $OUT/files.txt | wc -c)" 
xargs -0 grep -n -H -F -e '0.111' -e 'QC_AFAC' -e 'dht.mult' < $OUT/files.txt > $OUT/raw_hits.txt 2>>$OUT/grep_err.log
echo "grep_done $(wc -l < $OUT/raw_hits.txt)"
echo DONE
