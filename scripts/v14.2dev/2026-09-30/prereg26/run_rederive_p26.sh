#!/bin/bash
# load gated launcher for the PREREG26 re-derivation (integer part of the 1 minute load below 12). No em dashes.
cd /home/aaron/jobs/v142p26/verify_20260930
until [ "$(cut -d. -f1 /proc/loadavg)" -lt 12 ]; do sleep 30; done
echo "start $(date -Is) load $(cut -d" " -f1 /proc/loadavg)"
Rscript rederive_p26.R; echo "exit $? $(date -Is)"
