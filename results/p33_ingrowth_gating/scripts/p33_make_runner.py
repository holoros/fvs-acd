#!/usr/bin/env python3
# Pass 33: derive the short-interval scoring runner from the pass 24 merge_v24 runner, adding a
# P33_MATGATE env switch. The pass 24 runner is NOT edited in place; it stays the comparison
# baseline. Counted replacement, aborts on mismatch.
import sys
SRC_F = "/users/PUOM0008/crsfaaron/magplot/verify/merge_v24/2026-08-21_merge-v24-runner_WIP.R"
DST_F = "/users/PUOM0008/crsfaaron/magplot/verify/p33/2026-08-26_p33-matgate-runner.R"

s = open(SRC_F).read()
anchor = 'if (isTRUE(V1211_DHTHW))    { ops$use.dht.hw.mod <- TRUE }\n'
if s.count(anchor) != 1:
    print(f"ANCHOR MISMATCH count={s.count(anchor)}"); sys.exit(1)

add = anchor + '''## Pass 33 lever: maturity-gated ingrowth release (engine ops$use.ingrowth.matgate, default OFF
## in AcadianGY_13.1.r, so with P33_MATGATE unset this file is behaviourally identical to the
## pass 24 merge_v24 runner it was copied from).
P33_MATGATE <- as.logical(Sys.getenv("P33_MATGATE","FALSE"))
if (isTRUE(P33_MATGATE)) { ops$use.ingrowth.matgate <- TRUE
  ops$ingrowth.matgate.qc <- as.numeric(Sys.getenv("MATGATE_QC","12.7"))
  ops$ingrowth.matgate.k  <- as.numeric(Sys.getenv("MATGATE_K","0.6")) }
cat(sprintf("P33 lever: MATGATE=%s (qc=%s k=%s)\\n", P33_MATGATE,
  Sys.getenv("MATGATE_QC","12.7"), Sys.getenv("MATGATE_K","0.6")))
'''
s = s.replace(anchor, add, 1)
import os
os.makedirs(os.path.dirname(DST_F), exist_ok=True)
open(DST_F, "w").write(s)
print(f"WROTE {DST_F}")
