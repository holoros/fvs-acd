#!/bin/bash
## Pass 29 launcher. Waits (sleep 300 loop) until ~/jobs/v142htf/home/logs/_status.txt contains ALL_DONE, then runs
## step 1 (MNAP replacement in a database copy), the frozen pass 29 frame builder, and the gates, each with its own log.
## Status file ends with P29_DONE or P29_FAIL <step>. Never writes inside ~/jobs/v142htf. No em dashes.
J=/home/aaron/jobs/v142p29
ST=$J/logs/_status_p29.txt
HTF=/home/aaron/jobs/v142htf/home/logs/_status.txt
LOCK=$J/logs/launch_p29.pid
export R_LIBS_USER=/home/aaron/R/x86_64-pc-linux-gnu-library/4.5
export P29_JOB=$J
if [ -e "$LOCK" ] && kill -0 "$(cat "$LOCK")" 2>/dev/null; then echo "another launcher is running" >&2; exit 1; fi
echo $$ > "$LOCK"
echo "WAITING_FOR_HTF $(date -Is) pid $$" > "$ST"
echo "WAIT_SKIPPED start now per Aaron 26 Sep, nice 5" >> "$ST"
echo "HTF_ALL_DONE_SEEN $(date -Is)" >> "$ST"

run() {  # run <step> <done marker> <command...>
  local step=$1 marker=$2; shift 2
  echo "START $step $(date -Is)" >> "$ST"
  "$@" > "$J/logs/p29_${step}.log" 2>&1
  local rc=$?
  if [ $rc -ne 0 ] || ! grep -q "^$marker" "$J/logs/p29_${step}.log"; then
    grep '^GATE_FAIL' "$J/logs/p29_${step}.log" >> "$ST" 2>/dev/null
    echo "rc=$rc $(date -Is)" >> "$ST"
    echo "P29_FAIL $step" >> "$ST"
    rm -f "$LOCK"; exit 1
  fi
  echo "OK $step $(date -Is)" >> "$ST"
}

run step1 STEP1_DONE Rscript "$J/scripts/2026-09-26_pass29_step1_mnap-replace.R"
export GYR_DB=$J/db/ALL_Standardized_pass29_PROVISIONAL.sqlite
export GYR_DB_MD5=$(cat "$J/db/ALL_Standardized_pass29_PROVISIONAL.md5")
export GYR_OUT=$J/out/PROVISIONAL_p29
echo "DB_MD5 $GYR_DB_MD5" >> "$ST"
mkdir -p "$GYR_OUT/frames"
run builder GYR_BUILD_DONE Rscript "$J/scripts/2026-09-26_pass29_frame-builder.R"
run gates P29_GATES_DONE Rscript "$J/scripts/2026-09-26_pass29_gates.R"
(cd "$J/out" && find PROVISIONAL_p29 tables -type f -exec md5sum {} + | sort -k2) > "$J/logs/p29_outputs_md5.txt"
rm -f "$LOCK"
echo "P29_DONE" >> "$ST"
