#!/bin/sh
## Launches one R script only when the 1 minute load average is at or below 12 (track rule). Usage: script log [env]
cd /home/aaron/jobs/v142p29_nsrs
while :; do L=$(cut -d' ' -f1 /proc/loadavg); if [ "$(echo "$L <= 12" | bc)" = 1 ]; then break; fi; sleep 30; done
echo "launch at load $L $(date -Is)" > "$2.launch"
exec Rscript "$1" > "$2" 2>&1
