#!/bin/bash
# PREREG26: builds the long horizon driver from the frozen PREREG22 runner and records the diff. Refuses to overwrite.
set -euo pipefail; S=/home/aaron/jobs/v142p26/scripts; R=/home/aaron/jobs/v142p22/home/runner_p20_fb.R; D=$S/driver_p26.R
[ "$(md5sum $R | cut -d' ' -f1)" = 65392afbbe67e2e80524855fea7a41da ] || { echo "runner md5 mismatch"; exit 4; }
[ ! -e $D ] || { echo "REFUSE $D exists"; exit 3; }
{ cat $S/parts/head.txt; head -n 419 $R; cat $S/parts/p26_block.R; } > $D
diff -u $R $D > /home/aaron/jobs/v142p26/diffs/runner_p20_fb.R_to_driver_p26.R.diff || true
md5sum $D
