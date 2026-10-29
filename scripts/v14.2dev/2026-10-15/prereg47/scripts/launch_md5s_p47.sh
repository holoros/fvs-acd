#!/bin/bash
## PREREG47: record md5s of the plan, the thresholds file and its script, assemble_p47.R, the reference tables and every
## trajectory the assembly will read, before any reading (plan, Execution). One reading (tag r1) after the PREREG46 RESULT exists;
## a later reading takes its own tag and record. Writes to a temporary file and renames at the end, so a failure leaves no partial
## record. Refuses to overwrite. Usage: bash scripts/launch_md5s_p47.sh [arms] [tag]   (defaults: all five arms, r1)
set -euo pipefail
J=/home/aaron/jobs/v142p47
ARMS=${1:-qc141,p38_fit,qc_rh,qc_lz,qc_ez}; TAG=${2:-r1}
if [ "$TAG" = r1 ]; then L=$J/logs/launch_md5s.txt; else L=$J/logs/launch_md5s_$TAG.txt; fi
[ -e "$L" ] && { echo "REFUSE $L exists"; exit 1; }
[ -s "$J/logs/thresholds_md5.txt" ] || { echo "STOP: thresholds_p47.R has not recorded its md5"; exit 1; }
case ",$ARMS," in *,qc_lz,*|*,qc_ez,*) ls /home/aaron/jobs/v142p46/assembled/gyr142-p46-verdict_DATA_*.txt >/dev/null 2>&1 || { echo "STOP: PREREG46 RESULT absent"; exit 1; };; esac
T=$(mktemp "$J/logs/.launch_p47.XXXXXX"); trap 'rm -f "$T"' EXIT
{
  cd "$J"
  md5sum plan/2026-10-15_v142_qc-bakuzis-absolute_PREREG47r5.md plan/2026-10-15_v142_qc-bakuzis-absolute_PREREG47r4.md plan/2026-10-15_v142_qc-bakuzis-absolute_PREREG47r3.md plan/2026-10-15_v142_qc-bakuzis-absolute_PREREG47r2.md plan/2026-10-11_v142_qc-bakuzis-absolute_PREREG47.md plan/thresholds_p47_DATA.csv scripts/thresholds_p47.R scripts/assemble_p47.R
  md5sum /home/aaron/jobs/v142p44/scripts/assemble_p44_r2.R /home/aaron/jobs/v142p44/assembled/gyr142-p44-relations_DATA_2026-10-05.csv \
    /home/aaron/jobs/v142p45/assembled/gyr142-p45-relations_DATA_2026-10-05.csv /home/aaron/jobs/v142p45/assembled/gyr142-p45-credibility_DATA_2026-10-05.csv \
    /home/aaron/jobs/v142p45/plan/frontier_p45_DATA.csv /home/aaron/jobs/v142p45st/scripts/st2_offset.R \
    /home/aaron/jobs/v142p45st/assembled/st2_gatec-offset_DATA_2026-10-05.csv /home/aaron/jobs/v142p31/assembled/thresholds_p31_DATA_2026-09-30.csv
  for a in ${ARMS//,/ }; do
    case $a in qc141|p38_fit) d=/home/aaron/jobs/v142p44/out;; qc_rh) d=/home/aaron/jobs/v142p45/out;; qc_lz|qc_ez) d=/home/aaron/jobs/v142p46/out;; *) echo "unknown arm $a" >&2; exit 1;; esac
    for s in 1 2 3; do md5sum "$d/traj_${a}_S$s.csv"; done
  done
  echo "recorded $(date +%Y-%m-%dT%H:%M:%S%z) before PREREG47 reading $TAG"
} > "$T"
mv -n "$T" "$L"; trap - EXIT
[ -e "$L" ] && cat "$L"
