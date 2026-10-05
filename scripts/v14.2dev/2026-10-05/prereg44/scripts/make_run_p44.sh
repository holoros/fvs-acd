#!/bin/bash
# PREREG44: writes run_p44.sh from the PREREG41 wrapper run_p41.sh (md5 d7fd3101) with only the job paths, the log tag, the
# driver (driver_p44.R, md5 checked) and one added export (P44_STANDS from the fourth argument) changed. Refuses to overwrite.
set -euo pipefail; J=/home/aaron/jobs/v142p44; S=$J/scripts; W=/home/aaron/jobs/v142p41/scripts/run_p41.sh; O=$S/run_p44.sh
[ "$(md5sum $W | cut -d' ' -f1)" = d7fd3101f2b41a12eddaf34116a6b050 ] || { echo "run_p41 md5 mismatch"; exit 4; }
[ ! -e $O ] || { echo "REFUSE $O exists"; exit 3; }; DM=$(md5sum $S/driver_p44.R | cut -d' ' -f1)
{ echo "# PREREG44 task wrapper: run_p41.sh (md5 d7fd3101) with job paths, log tag and driver changed and P44_STANDS exported; diff in ../diffs/."
  sed -e 's#/home/aaron/jobs/v142p41#/home/aaron/jobs/v142p44#g' -e 's/\[p41\]/[p44]/g' \
      -e "s#D=/home/aaron/jobs/v142p31/scripts/driver_p31.R; chk \$D 467fb5188a868ed4be4cba9e5a53a3dc#D=$S/driver_p44.R; chk \$D $DM#" \
      -e 's#^export P31_MODE=\$MODE#export P44_STANDS=$CELLS\nexport P31_MODE=$MODE#' $W; } > $O
[ "$(grep -c "driver_p44.R; chk" $O)" = 1 ] || { echo "driver line not replaced"; exit 5; }
[ "$(grep -c '^export P44_STANDS' $O)" = 1 ] || { echo "export not added"; exit 6; }
grep -q v142p41 $O && { echo "p41 path left"; exit 7; }
diff -u $W $O > $J/diffs/run_p41.sh_to_run_p44.sh.diff || true; md5sum $O
