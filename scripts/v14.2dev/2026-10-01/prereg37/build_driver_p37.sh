#!/bin/bash
# Builds driver_p37.R: header, runner lines 1 to 419 byte for byte (v142p28/home/runner_p28_fb.R, md5 0a2b2742), then
# parts/p37_block.R with P37_DHT_EXPR replaced by the p31_dht definition line (runner line 425's dht.mult expression) copied
# from v142p31/scripts/driver_p31.R line 438. Refuses to overwrite. No em dashes.
set -euo pipefail
S=/home/aaron/jobs/v142p37/scripts; R=/home/aaron/jobs/v142p28/home/runner_p28_fb.R; D31=/home/aaron/jobs/v142p31/scripts/driver_p31.R
[ "$(md5sum $R | cut -d' ' -f1)" = 0a2b27421ee7b25eaab7f4591ce3af97 ] || { echo bad runner md5; exit 4; }
[ "$(md5sum $D31 | cut -d' ' -f1)" = 467fb5188a868ed4be4cba9e5a53a3dc ] || { echo bad p31 driver md5; exit 4; }
O=$S/driver_p37.R; [ ! -e $O ] || { echo REFUSE $O; exit 3; }
L438=$(sed -n 438p $D31); case "$L438" in "p31_dht <- function(p, it)"*) ;; *) echo "line 438 is not p31_dht"; exit 5;; esac
{ echo "# PREREG37 OFFLINE dht DRIVER (2026-10-01), built by build_driver_p37.sh: this header, runner lines 1 to 419 of"
  echo "# ~/jobs/v142p28/home/runner_p28_fb.R (md5 0a2b27421ee7b25eaab7f4591ce3af97) byte for byte, then parts/p37_block.R."
  echo "# No engine file is edited; calc_dht is wrapped by a recorder that calls the original. No coordinates. No em dashes."
  sed -n 1,419p $R
  while IFS= read -r line; do if [ "$line" = "P37_DHT_EXPR" ]; then printf '%s\n' "$L438"; else printf '%s\n' "$line"; fi; done < $S/parts/p37_block.R
} > $O
md5sum $O $S/parts/p37_block.R
