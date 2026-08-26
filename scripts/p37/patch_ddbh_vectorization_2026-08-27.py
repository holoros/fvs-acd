#!/usr/bin/env python3
"""
Vectorization fix for calc_ddbh's ddbh_hw_mod call site.

ddbh_hw_mod is a SCALAR function whose leading validity gate is an `if`. calc_ddbh called it
bare inside dplyr::mutate/ifelse, handing it whole columns, which under R >= 4.2 raises
"the condition has length > 1". Applied element-wise with purrr::pmap_dbl, exactly as
ddbh_thin_mod, ddbh_sbw_mod, dht_hw_mod, tsurv_sbw_mod and tsurv_hw_mod already are in the
same files. Function bodies are NOT touched, so numerics are unchanged by construction.

Backs each file up with a .PREV_20260827 suffix before writing.
"""
import re, shutil, sys, os

FILES = [
    "/users/PUOM0008/crsfaaron/AcadianGY_13.1.r",
    "/users/PUOM0008/crsfaaron/AcadianGY_13.3.r",
    "/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd/scripts/AcadianGY_13.1_DRAFT.r",
    "/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd/scripts/AcadianGY_13.3_DRAFT.r",
    "/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd/scripts/AcadianGY_12.11.r",
]

CALL_RE = re.compile(
    r"ddbh_hw_mod\(sp = sp, dbh = dbh, bal = bal,[ \t]*\n"
    r"[ \t]*form = form, risk = risk,[ \t]*\n"
    r"[ \t]*spp\.coeff = hw\.mod\.spp\.coeff,[ \t]*\n"
    r"[ \t]*dbh\.interaction = hw\.mod\.dbh\.interaction\)"
)

NEW_CALL = (
    "purrr::pmap_dbl(list(sp = sp, dbh = dbh, bal = bal,\n"
    "                                                                     form = form, risk = risk,\n"
    "                                                                     spp.coeff = hw.mod.spp.coeff,\n"
    "                                                                     dbh.interaction = hw.mod.dbh.interaction),\n"
    "                                                                ddbh_hw_mod)"
)

MUTATE_LINE = "      dplyr::mutate(ddbh.form.risk.mod = ifelse(!is.na(form) & !is.na(risk),\n"

COMMENT = (
    "      # VECTORIZATION FIX, 27 August 2026. ddbh_hw_mod is a SCALAR function whose leading\n"
    "      # validity gate is an `if`, so handing it whole columns raised \"the condition has\n"
    "      # length > 1\" under R >= 4.2 the moment a stand carried a tree with a non-NA form and\n"
    "      # risk, i.e. any hardwood. ifelse() evaluates its `yes` branch only when at least one\n"
    "      # element of the test is TRUE, so an all-softwood stand never triggered it and projected\n"
    "      # normally, while a stand with even one hardwood errored out of AcadianGYOneStand and was\n"
    "      # silently discarded by the benchmark runner's per-stand tryCatch. Applied element-wise\n"
    "      # with purrr::pmap_dbl, which is the convention this same file already uses for\n"
    "      # ddbh_thin_mod, ddbh_sbw_mod, dht_hw_mod, tsurv_sbw_mod and tsurv_hw_mod. This is a\n"
    "      # vectorization fix ONLY: ddbh_hw_mod's body is untouched and each row receives exactly\n"
    "      # the scalar arguments the original call intended, so no modifier's numerical behaviour\n"
    "      # changes. The outer ifelse gate is retained for readability and is redundant with\n"
    "      # ddbh_hw_mod's own is.na(form)/is.na(risk) gate, which returns 1 for those rows anyway.\n"
)

rc = 0
for path in FILES:
    if not os.path.exists(path):
        print("MISSING  %s" % path); rc = 1; continue
    src = open(path, "r", encoding="utf-8", errors="surrogateescape").read()
    if "purrr::pmap_dbl(list(sp = sp, dbh = dbh, bal = bal," in src:
        print("ALREADY  %s" % path); continue
    n = len(CALL_RE.findall(src))
    if n != 1:
        print("SKIP     %s : found %d call sites matching the pattern (expected 1)" % (path, n))
        rc = 1
        continue
    if src.count(MUTATE_LINE) != 1:
        print("SKIP     %s : mutate anchor line not unique" % path); rc = 1; continue
    bak = path + ".PREV_20260827"
    if not os.path.exists(bak):
        shutil.copy2(path, bak)
    out = CALL_RE.sub(lambda m: NEW_CALL, src, count=1)
    out = out.replace(MUTATE_LINE, COMMENT + MUTATE_LINE, 1)
    open(path, "w", encoding="utf-8", errors="surrogateescape").write(out)
    print("PATCHED  %s   (backup %s)" % (path, bak))

sys.exit(rc)
