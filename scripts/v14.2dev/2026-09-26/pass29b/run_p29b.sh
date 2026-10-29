#!/bin/bash
## Pass 29b runner: builder (owner split) then gates. One process chain, nice 5. No em dashes.
J=/home/aaron/jobs/v142p29b; ST=$J/logs/_status_p29b.txt
export R_LIBS_USER=/home/aaron/R/x86_64-pc-linux-gnu-library/4.5 P29B_JOB=$J P29_IN=$J/in
export GYR_DB=$J/db/ALL_Standardized_pass29_PROVISIONAL.sqlite GYR_DB_MD5=f55bf733b628da91c08a519cdd00dc90
export GYR_OUT=$J/out/PROVISIONAL_p29b P29B_OWNERS=$J/out/tables/pass29-step1-plots_PROVISIONAL_DATA_2026-09-26.csv
echo "START $(date -Is) pid $$ prereg_md5 $(md5sum < $J/PREREG13b.md | cut -c1-32)" > "$ST"
run() {
  local step=$1 marker=$2; shift 2
  echo "START $step $(date -Is)" >> "$ST"
  nice -n 5 "$@" > "$J/logs/p29b_${step}.log" 2>&1; local rc=$?
  if [ $rc -ne 0 ] || ! grep -q "^$marker" "$J/logs/p29b_${step}.log"; then
    grep '^GATE_FAIL' "$J/logs/p29b_${step}.log" >> "$ST" 2>/dev/null
    echo "rc=$rc $(date -Is)" >> "$ST"; FAILSTEP=$step; return 1
  fi
  echo "OK $step $(date -Is)" >> "$ST"
}
fin() {
  (cd "$J/out" && find PROVISIONAL_p29b tables -type f -exec md5sum {} + | sort -k2) > "$J/logs/p29b_outputs_md5.txt"
  (cd "$J" && tar -czf out/pass29b_tables_PROVISIONAL_2026-09-26.tgz out/tables out/PROVISIONAL_p29b/*.csv PREREG13b.md diffs logs/p29b_*.log)
  md5sum "$J/out/pass29b_tables_PROVISIONAL_2026-09-26.tgz" >> "$ST"
}
run builder GYR_BUILD_DONE Rscript "$J/scripts/2026-09-26_pass29b_frame-builder.R" || { fin; echo "P29B_FAIL $FAILSTEP" >> "$ST"; exit 1; }
run gates P29B_GATES_DONE Rscript "$J/scripts/2026-09-26_pass29b_gates.R" || { fin; echo "P29B_FAIL $FAILSTEP" >> "$ST"; exit 1; }
fin
echo "P29B_DONE" >> "$ST"
