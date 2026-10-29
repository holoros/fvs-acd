#!/usr/bin/env python3
# Pass 33: derive bakuzis_p33_traj.R from bakuzis_h1default_traj.R with a VARIANT env switch
# (h1check | noing | matgate). Every replacement is counted and the script aborts on any
# unexpected count, so a drifted upstream file cannot be silently half-transformed.
import sys

SRC_F = "/users/PUOM0008/crsfaaron/magplot/verify/bakuzis_h1default_traj.R"
DST_F = "/users/PUOM0008/crsfaaron/magplot/verify/bakuzis_p33_traj.R"

s = open(SRC_F).read()

def rep(text, old, new, n_expect):
    n = text.count(old)
    if n != n_expect:
        print(f"REPLACE MISMATCH: {old[:60]!r} count={n} expected={n_expect}")
        sys.exit(1)
    return text.replace(old, new)

s = rep(s,
    'OUT_DIR   <- Sys.getenv("OUT_DIR", "/users/PUOM0008/crsfaaron/magplot/verify/bakuzis_h1")',
    'OUT_DIR   <- Sys.getenv("OUT_DIR", "/users/PUOM0008/crsfaaron/magplot/verify/bakuzis_p33")', 1)

mort_line = "ops$mort.dens.fmin <- 0.13; ops$mort.dens.k <- 12.4; ops$mort.dens.rd0 <- 0.38\n"
variant_block = mort_line + '''
## ---- pass 33 VARIANT switch --------------------------------------------------------------------
## h1check: exact h1default config (regression gate G1, must be byte-identical to pass 32 output)
## noing:   h1default + zero recruitment everywhere (ceiling probe: bounds ANY ingrowth-side fix)
## matgate: h1default + ops$use.ingrowth.matgate (h2 candidate lever, engine defaults qc=12.7 k=0.6)
VARIANT <- Sys.getenv("VARIANT", "h1check")
if (VARIANT == "noing") {
  ops$ingrowth.mult <- 0
  ops$ingrowth.mult.region <- list(c(NB = 0, QC = 0))
} else if (VARIANT == "matgate") {
  ops$use.ingrowth.matgate <- TRUE
} else if (VARIANT != "h1check") stop("VARIANT must be h1check, noing, or matgate")
ORIGIN_LAB <- switch(VARIANT, h1check = "h1_v132_mortgate", noing = "h1_noingrowth", matgate = "h2_matgate")
cat(sprintf("[%s] pass33 VARIANT=%s origin=%s\\n", SRC, VARIANT, ORIGIN_LAB))
'''
s = rep(s, mort_line, variant_block, 1)
s = rep(s, 'origin="h1_v132_mortgate"', 'origin=ORIGIN_LAB', 1)

n_tag = s.count('"_h1default_')
if n_tag < 2:
    print(f"TAG COUNT SUSPICIOUS: {n_tag}"); sys.exit(1)
s = rep(s, '"_h1default_', '"_", VARIANT, "_', n_tag)

open(DST_F, "w").write(s)
print(f"WROTE {DST_F}; filename-tag replacements={n_tag}")
