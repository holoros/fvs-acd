#!/usr/bin/env python3
"""
Second vectorization fix, tsurv_hw_mod call site. 27 August 2026.

Only reachable once the calc_ddbh fix is in place, because calc_ddbh errored first. tsurv_hw_mod is
already applied element-wise with purrr::pmap_dbl, yet ifelse() evaluates its `yes` branch over
EVERY row, so softwood rows the gate exists to exclude still reach the function, whose first
statement is a bare `if (form == 'F1')`. A softwood carries form NA after split_formrisk, so that
`if` raises "missing value where TRUE/FALSE needed".

The guard is a CALL-SITE wrapper only. tsurv_hw_mod's body is untouched and every row the
surrounding gate admits calls it with byte-identical arguments.

Backs each file up with a .PREV2_20260827 suffix before writing.
"""
import re, shutil, sys, os

FILES = [
    "/users/PUOM0008/crsfaaron/AcadianGY_13.1.r",
    "/users/PUOM0008/crsfaaron/AcadianGY_13.3.r",
    "/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd/scripts/AcadianGY_13.1_DRAFT.r",
    "/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd/scripts/AcadianGY_13.3_DRAFT.r",
    "/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd/scripts/AcadianGY_12.11.r",
]

OLD_RE = re.compile(
    r"([ \t]*)dplyr::mutate\(tsurv\.hw\.mod = ifelse\((?P<gate>[^\n]*),[ \t]*\n"
    r"[ \t]*purrr::pmap_dbl\(list\(dbh, bal, ba\.plot, form, b0, b1\),[ \t]*\n"
    r"[ \t]*tsurv_hw_mod\),[ \t]*\n"
    r"[ \t]*1\)\)"
)

COMMENT = (
    "      # VECTORIZATION FIX (2), 27 August 2026. Companion to the calc_ddbh fix above, and only\n"
    "      # reachable once that one is in place, since calc_ddbh errored first and masked this.\n"
    "      # tsurv_hw_mod is already applied element-wise with purrr::pmap_dbl, yet ifelse()\n"
    "      # evaluates its `yes` branch over EVERY row, so the softwood rows the gate exists to\n"
    "      # exclude still reach the function, whose first statement is a bare `if (form == 'F1')`.\n"
    "      # A softwood carries form NA after split_formrisk, so that `if` raised \"missing value\n"
    "      # where TRUE/FALSE needed\" and the stand was discarded by the runner's per-stand\n"
    "      # tryCatch exactly as the calc_ddbh defect discarded it. Unlike ddbh_hw_mod, dht_hw_mod,\n"
    "      # ddbh_thin_mod and ddbh_sbw_mod, tsurv_hw_mod carries no NA-safe validity gate of its\n"
    "      # own. The guard below is a CALL-SITE wrapper only: tsurv_hw_mod's body is untouched and\n"
    "      # the wrapper short-circuits exactly the rows the surrounding ifelse gate discards\n"
    "      # anyway, returning a placeholder 1 that ifelse() then throws away. Every row the gate\n"
    "      # admits calls tsurv_hw_mod with byte-identical arguments, so no modifier's numerical\n"
    "      # behaviour changes.\n"
)

rc = 0
for path in FILES:
    if not os.path.exists(path):
        print("MISSING  %s" % path); rc = 1; continue
    src = open(path, "r", encoding="utf-8", errors="surrogateescape").read()
    if ".tsurvhw_guard" in src:
        print("ALREADY  %s" % path); continue
    ms = list(OLD_RE.finditer(src))
    if len(ms) != 1:
        print("SKIP     %s : found %d tsurv_hw_mod call sites (expected 1)" % (path, len(ms)))
        rc = 1
        continue
    m = ms[0]
    indent = m.group(1)
    gate = m.group("gate")
    new = (
        COMMENT
        + indent + "dplyr::mutate(tsurv.hw.mod = ifelse(" + gate + ",\n"
        + indent + "                                    purrr::pmap_dbl(list(dbh, bal, ba.plot, form, b0, b1),\n"
        + indent + "                                                    .tsurvhw_guard),\n"
        + indent + "                                    1))"
    )
    bak = path + ".PREV2_20260827"
    if not os.path.exists(bak):
        shutil.copy2(path, bak)
    out = src[:m.start()] + new + src[m.end():]

    # Define the guard immediately after tsurv_hw_mod's definition closes, so it travels with the
    # function rather than living at the call site as an anonymous lambda.
    anchor = "  hw.surv.mod\n  \n}\n"
    if out.count(anchor) != 1:
        print("SKIP     %s : tsurv_hw_mod closing anchor not unique" % path); rc = 1; continue
    guard_def = anchor + (
        "\n"
        "# Call-site NA guard for tsurv_hw_mod (27 August 2026). tsurv_hw_mod's leading `if (form ==\n"
        "# 'F1')` is not NA-safe, and the mortality call site's ifelse() gate evaluates its `yes`\n"
        "# branch over every row, softwoods included, which carry form NA. This wrapper returns a\n"
        "# placeholder 1 for exactly the rows that gate discards, and delegates unchanged otherwise.\n"
        "# It adds NO numerical behaviour: every row the gate admits reaches tsurv_hw_mod with\n"
        "# byte-identical arguments.\n"
        ".tsurvhw_guard = function(dbh, bal, ba.plot, form, b0, b1) {\n"
        "  if (is.na(form) || is.na(b0)) return(1)\n"
        "  tsurv_hw_mod(dbh = dbh, bal = bal, ba.plot = ba.plot, form = form, b0 = b0, b1 = b1)\n"
        "}\n"
    )
    out = out.replace(anchor, guard_def, 1)
    open(path, "w", encoding="utf-8", errors="surrogateescape").write(out)
    print("PATCHED  %s   (backup %s)" % (path, bak))

sys.exit(rc)
