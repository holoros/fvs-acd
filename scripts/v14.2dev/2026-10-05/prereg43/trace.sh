#!/bin/bash
# Tracing pass (not part of the literal hit set): lines naming the AFAC anchor factors with fit/derive wording, non csv files
OUT=~/jobs/v142p43/search_a
tr '\0' '\n' < $OUT/files.txt | grep -v '\.csv$' | tr '\n' '\0' | xargs -0 grep -n -H -i -E 'afac' 2>/dev/null > $OUT/trace_afac_raw.txt
echo DONE $(wc -l < $OUT/trace_afac_raw.txt)
