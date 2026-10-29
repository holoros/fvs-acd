#!/usr/bin/env python3
# =====================================================================================
# Build the p38 scorer from the p37 scorer by transformation, so the observed-basis gate,
# per-source cluster rules, physical validity screen, 5,000-resample cluster bootstrap,
# TOST apparatus, and the paired cluster-bootstrap delta carry over unchanged rather than
# being reimplemented. 27 August 2026.
#
# The p38 benchmark asks a different question with the same machinery:
#   arm A  fiaoff  = p37's CANDIDATE arm files (AcadianGY_13.3.r lineage, use.hw.mod ON,
#                    SM survival sub-flag OFF). Reused rather than rerun: the p38 unit
#                    probe proves the OFF state multiplies tsurv by exactly 1, and the
#                    off-state acceptance job proves byte-identical result files.
#   arm B  fiaon   = p38_fiaon files (same engine, same levers, USE_HW_SURV_FIA=TRUE).
# The only rows that can differ are sugar maple; every SM-free source must score
# identically BY CONSTRUCTION, and is scored anyway as a confirmation.
#
# Transformations, each assertion-checked:
#   registry: model prodhw   -> fiaoff, files p37_prodhw_* -> p37_cand_*   (arm A)
#             model v133cand -> fiaon,  files P37/p37_cand_* -> P38/p38_fiaon_*  (arm B)
#   names:    every remaining "prodhw" -> "fiaoff", "v133cand" -> "fiaon"
#   output:   OUT -> p38/out, every "p37-" output filename -> "p38-"
#   header:   provenance note prepended
# =====================================================================================
import re, sys

SRC = "scripts/p37/2026-08-27_p37_score.R"
DST = "scripts/p38/2026-08-27_p38_score.R"
src = open(SRC, encoding="utf-8").read()
lines = src.split("\n")

out, n_a, n_b = [], 0, 0
for ln in lines:
    if 'model="v133cand", cell=' in ln:
        ln = (ln.replace('file.path(P37,"p37_cand_', 'file.path(P38,"p38_fiaon_')
                .replace('model="v133cand"', 'model="fiaon"'))
        assert "p38_fiaon_" in ln and "P38" in ln, ln
        n_b += 1
    elif 'model="prodhw", cell=' in ln:
        ln = (ln.replace('file.path(P37,"p37_prodhw_', 'file.path(P37,"p37_cand_')
                .replace('model="prodhw"', 'model="fiaoff"'))
        assert "p37_cand_" in ln, ln
        n_a += 1
    out.append(ln)
assert n_a == 12 and n_b == 12, (n_a, n_b)
txt = "\n".join(out)

# remaining model-name references (PRIMARY, loops, labels, comments)
txt = txt.replace('"prodhw"', '"fiaoff"').replace('"v133cand"', '"fiaon"')
txt = txt.replace("v133cand MINUS prodhw", "fiaon MINUS fiaoff")

# output namespace
assert txt.count('OUT <- file.path(P37, "out")') == 1
txt = txt.replace('OUT <- file.path(P37, "out")', 'OUT <- file.path(P38, "out")')
assert txt.count('P37 <- file.path(V, "p37")') == 1
txt = txt.replace('P37 <- file.path(V, "p37")',
                  'P37 <- file.path(V, "p37")\nP38 <- file.path(V, "p38")')
n = txt.count('"p37-'); txt = txt.replace('"p37-', '"p38-')
assert n >= 5, n

header = """## =============================================================================================
## Pass 38 scoring: the sugar maple FIA survival modifier (tsurv_hw_mod_fia, ops$use.hw.surv.fia),
## two arms. BUILT BY TRANSFORMATION from scripts/p37/2026-08-27_p37_score.R by
## scripts/p38/build_p38_scorer_2026-08-27.py; the gate, cluster rules, physical screen,
## bootstrap and TOST apparatus are inherited, not reimplemented. Arms:
##   fiaoff  p37's candidate-arm result files reused as baseline (engine lineage identical,
##           sub-flag off; off-state neutrality proven by unit probe + byte-identity acceptance)
##   fiaon   p38_fiaon files, same engine and levers with USE_HW_SURV_FIA=TRUE
## Only sugar maple rows can differ; SM-free sources are scored as isolation confirmation.
## The p37 header below is retained verbatim for the inherited discipline.
## =============================================================================================
"""
txt = header + txt

open(DST, "w", encoding="utf-8").write(txt)
print(f"BUILT {DST}: armA rows {n_a}, armB rows {n_b}, p37->p38 outputs {n}")
for frag in ['model="fiaoff"', 'model="fiaon"', 'PRIMARY <- c("fiaoff","fiaon")',
             'file.path(P38, "out")', 'p38_fiaon_ns_long_unmanaged_results.csv']:
    assert frag in txt, f"POST-CHECK FAIL: {frag}"
print("post-checks OK")
