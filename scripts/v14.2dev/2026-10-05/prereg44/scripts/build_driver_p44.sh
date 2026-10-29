#!/bin/bash
# PREREG44: builds driver_p44.R from driver_p31.R (two checked edits, see parts/head44.txt) and records the diff. Refuses to overwrite.
set -euo pipefail; J=/home/aaron/jobs/v142p44; S=$J/scripts; P=/home/aaron/jobs/v142p31/scripts/driver_p31.R; D=$S/driver_p44.R
[ "$(md5sum $P | cut -d' ' -f1)" = 467fb5188a868ed4be4cba9e5a53a3dc ] || { echo "driver_p31 md5 mismatch"; exit 4; }
[ ! -e $D ] || { echo "REFUSE $D exists"; exit 3; }
python3 - "$P" "$S" "$D" <<'PY'
import sys
P, S, D = sys.argv[1:]
src = open(P).read(); head = open(f"{S}/parts/head44.txt").read(); br = open(f"{S}/parts/slgrid_branch.R").read()
a_old = 'if (!(P31_MODE %in% c("g0","grid"))'; a_new = 'if (!(P31_MODE %in% c("g0","grid","slgrid"))'
b_old = 'if (P31_MODE == "g0") {\n'
assert src.count(a_old) == 1, "edit 1 anchor not unique"; assert src.count(b_old) == 1, "edit 2 anchor not unique"
assert br.endswith('} else if (P31_MODE == "g0") {\n')
out = head + src.replace(a_old, a_new).replace(b_old, br)
open(D, "w").write(out); print("built", D)
PY
mkdir -p $J/diffs; diff -u $P $D > $J/diffs/driver_p31.R_to_driver_p44.R.diff || true
echo "added lines $(grep -c '^+[^+]' $J/diffs/driver_p31.R_to_driver_p44.R.diff) removed lines $(grep -c '^-[^-]' $J/diffs/driver_p31.R_to_driver_p44.R.diff)"
md5sum $D
