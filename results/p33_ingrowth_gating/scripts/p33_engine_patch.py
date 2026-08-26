#!/usr/bin/env python3
# Pass 33: insert the ops$use.ingrowth.matgate lever (default OFF, byte-identical when off)
# into AcadianGY_13.1.r, immediately after the density-release .rel computation and before
# the line that applies it to plot.data$ingrowth.ph. Idempotent: refuses to double-apply.
import sys, shutil, datetime

ENGINE = "/users/PUOM0008/crsfaaron/AcadianGY_13.1.r"
BACKUP = ENGINE + "_PREV_20260826"

src = open(ENGINE).read()
if "use.ingrowth.matgate" in src:
    print("ALREADY APPLIED, no change"); sys.exit(0)

anchor = '        .rel = 1 / (1 + exp(.ir_k * (dplyr::coalesce(plot.data$rd.mod, 0) - .ir_c)))\n'
apply_line = '        plot.data$ingrowth.ph = plot.data$ingrowth.ph * .rel\n'
n_anchor = src.count(anchor)
n_apply = src.count(anchor + apply_line)
if n_anchor != 1 or n_apply != 1:
    print(f"ANCHOR MISMATCH: anchor count={n_anchor}, anchor+apply count={n_apply}; aborting")
    sys.exit(1)

lever = (
"        # v13.3 CANDIDATE (pass 33): size-structure (maturity) gate on density-released\n"
"        # ingrowth. Gated ops$use.ingrowth.matgate (default FALSE => .rel unchanged, this\n"
"        # block byte-identical to pass 31/32 behavior). When TRUE, .rel is further scaled by\n"
"        # g(QMD) = 1/(1+exp(k*(qmd - qc))), qc default 12.7 cm (the FIA seedling-sapling to\n"
"        # poletimber stand-size boundary, 5 in), k default 0.6. Rationale (pass 32 Bakuzis\n"
"        # diagnosis, results/bakuzis/): after an sdimort-driven mid-rotation crash, the RD-only\n"
"        # release refills the freed density headroom with volume-free recruits, so stem count\n"
"        # rebuilds while volume does not and the stand stagnates below its pre-crash volume.\n"
"        # Reserving the release pulse for juvenile size structures (QMD near or below qc)\n"
"        # leaves a crashed mature stand's headroom to survivor BA/volume recovery instead.\n"
"        .mg_on = tryCatch(if (!is.null(ops$use.ingrowth.matgate)) isTRUE(ops$use.ingrowth.matgate) else FALSE, error=function(e) FALSE)\n"
"        if (.mg_on) {\n"
"          .mg_qc = tryCatch(if (!is.null(ops$ingrowth.matgate.qc) && !is.na(ops$ingrowth.matgate.qc)) ops$ingrowth.matgate.qc else 12.7, error=function(e) 12.7)\n"
"          .mg_k  = tryCatch(if (!is.null(ops$ingrowth.matgate.k)  && !is.na(ops$ingrowth.matgate.k))  ops$ingrowth.matgate.k  else 0.6,  error=function(e) 0.6)\n"
"          .rel = .rel * (1 / (1 + exp(.mg_k * (dplyr::coalesce(plot.data$qmd, 0) - .mg_qc))))\n"
"        }\n"
)

shutil.copy2(ENGINE, BACKUP)
out = src.replace(anchor + apply_line, anchor + lever + apply_line, 1)
open(ENGINE, "w").write(out)
print(f"PATCHED {ENGINE}; backup at {BACKUP}; added {len(lever.splitlines())} lines")
