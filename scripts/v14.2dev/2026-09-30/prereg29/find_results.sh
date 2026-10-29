#!/bin/sh
cd /home/aaron/jobs
find . -maxdepth 7 -name 'gyr_v141LT*results*.csv' -not -path './v142p29/*' -not -path './v142p29b/*' | xargs -r md5sum | sort -k2 > /home/aaron/jobs/v142p29_nsrs/logs/find_results.txt
echo FIND_DONE
