#!/bin/sh
find /home/aaron -xdev \( -name 'gyr_v141LT_*_results.csv' -o -name '*bench141*' \) -not -path '*/v142p29/*' -not -path '*/v142p29b/*' 2>/dev/null | head -200 > /home/aaron/jobs/v142p29_nsrs/logs/find2.txt
echo FIND2_DONE
