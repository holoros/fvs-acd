#!/usr/bin/env python3
# build_v130_baonly_v2.py
#
# Phase 2 BA-only builder, v2 (over-correction fix). Transforms the FROZEN base
# AcadianGY_12.10.1.r into AcadianGY_13.0.r by applying ONLY the basal-area
# net-increment anchor (EDIT2a/2b/2c). The v13.0 dominant-height correction is
# delivered through the harness-native ops$esi.anchor.coef hook (see
# fit_v130_esi_anchor.R and bench_parity_v130.R), NOT as a model-file edit.
#
# WHY v2 EXISTS
# -------------
# build_v130_baonly.py inverted BA bias from -9.81% to +9.83% pooled (NB to
# +25.96%, QMD_small to +35.75%). Root cause, diagnosed in
# v130_BA_overcorrection_diagnosis.md: the BA correction read its per-step time
# length from `tree$year[1]`, but in this model `tree$year` is the CUMULATIVE
# elapsed-year counter, not the length of the current step. The harness calls
# AcadianGYOneStand once per year and increments `year` by one inside every call
# (Output block, `year = year + 1`), so on call k the correction demanded a net
# BA increment of `tnet * k` in a single one-year growth step, instead of
# `tnet * 1`. That escalating demand pinned the survivor diameter-increment scale
# at its clamp ceiling for the back half of every multi-year interval, roughly
# doubling the intended nudge and inverting the bias.
#
# WHAT v2 CHANGES (two edits inside the inserted R, nothing else)
# --------------------------------------------------------------
#   FIX 1 (decisive): the step is now the model's OWN within-call clock advance,
#          `.v130_step <- tree$year[1] - .v130_year0`, where `.v130_year0` is the
#          entry-year snapshot added to EDIT2a. This is exactly 1 for the annual
#          harness loop and generalizes to any true multi-year step. It replaces
#          the buggy `.v130_step <- tree$year[1]` (the absolute clock).
#   FIX 2 (guard + hedge): the survivor-increment scale is tightened from the far
#          too loose single-year band [0.25, 4] to a physically sane [0.7, 1.5],
#          and a bounded-nudge gain `ops$ba.anchor.gain` in [0, 1] shrinks the
#          solved scale toward 1. Gain defaults to 1 (the intended exact per-year
#          match, now safe because the step is correct). If the smoke test shows
#          the corrected exact match still over-adds on near-asymptotic mature NB
#          stands (the residual anchor-transfer risk), set ops$ba.anchor.gain
#          to about 0.5 for a damped nudge.
#
# The net-vs-gross basis is UNCHANGED because it was already correct: `.v130_ba0`
# is snapshotted at entry pre-growth, and the correction runs after growth, after
# SDImax mortality, and after ingrowth append, so it matches true end-of-step NET
# stand BA with ingrowth held fixed.
#
# Like v1, this does NOT rewrite the file. It reads the source, applies each edit
# as a regex substitution that MUST match its anchor exactly once, and writes the
# result. If any anchor is found zero times or more than once, it prints an
# ANCHOR ERROR and exits(2) WITHOUT writing output.
#
# Default input  ~/_scripts/AcadianGY_12.10.1.r  (the frozen operational base)
# Default output ~/AcadianGY_13.0.r
#
# COLUMN CASING ASSUMPTION: the inserted R blocks assume lowercase tree-list
# columns (dbh, expf, tree, ht, year, cr, hcb), consistent with comprehensive_bench.R
# (year=0, dbh, expf, tree) and the height-block code in this function. If the
# build uses uppercase columns, adjust the casing in the two inserted blocks.
#
# No em dashes anywhere in this file.

import os
import re
import sys
import difflib


def die_anchor(name, n):
    print("ANCHOR ERROR: {} found {} times".format(name, n))
    sys.exit(2)


def flex(literal, ws=r"[ \t]*"):
    """Escape a literal for regex, relaxing internal spaces to flexible whitespace.

    Uses a within-line whitespace class by default so a pattern cannot silently
    span multiple lines. Pass ws=r"\\s*" where newline-spanning is intended.
    """
    esc = re.escape(literal)
    # Normalize any escaped space (older Python) to a plain space, then relax.
    esc = esc.replace("\\ ", " ")
    esc = esc.replace(" ", ws)
    return esc


def replace_line(text, name, core, new_lines):
    """Replace exactly one whole line whose trimmed content matches `core`.

    Preserves the matched line's leading indentation and applies it to each of
    the replacement lines.
    """
    pat = re.compile(r"(?m)^([ \t]*)" + flex(core) + r"[ \t]*$")
    matches = list(pat.finditer(text))
    if len(matches) != 1:
        die_anchor(name, len(matches))
    m = matches[0]
    indent = m.group(1)
    repl = "\n".join(indent + ln for ln in new_lines)
    return text[:m.start()] + repl + text[m.end():]


def insert_after_signature(text, name, block_lines, indent="  "):
    """Insert a block right after the opening brace of the AcadianGYOneStand body."""
    pat = re.compile(
        r"(AcadianGYOneStand\s*(?:<-|=)\s*function\s*\([^)]*\)\s*\{)"
    )
    matches = list(pat.finditer(text))
    if len(matches) != 1:
        die_anchor(name, len(matches))
    m = matches[0]
    block = "\n" + "\n".join((indent + ln) if ln else "" for ln in block_lines)
    return text[:m.end()] + block + text[m.end():]


def insert_before_comment(text, name, anchor_core, block_lines):
    """Insert a block on the lines immediately before a matched comment line.

    The comment line itself is preserved; the block inherits the comment's indent.
    """
    pat = re.compile(r"(?m)^([ \t]*)" + flex(anchor_core) + r"[ \t]*$")
    matches = list(pat.finditer(text))
    if len(matches) != 1:
        die_anchor(name, len(matches))
    m = matches[0]
    indent = m.group(1)
    block = "\n".join((indent + ln) if ln else "" for ln in block_lines)
    return text[:m.start()] + block + "\n" + text[m.start():]


def main():
    inp = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/_scripts/AcadianGY_12.10.1.r")
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.expanduser("~/AcadianGY_13.0.r")

    with open(inp, "r") as fh:
        original = fh.read()

    text = original

    # ---------------------------------------------------------------------
    # NOTE: EDIT 1 (the dominant-height Chapman-Richards swap) is
    # INTENTIONALLY OMITTED. The v13.0 height correction is applied at runtime
    # through ops$use.esi.anchor.recal + ops$esi.anchor.coef in the harness.
    # No height edit to the model file.
    # ---------------------------------------------------------------------

    # ---------------------------------------------------------------------
    # EDIT 2: BA net-increment anchor (v2 over-correction fix).
    # ---------------------------------------------------------------------

    # (2a) start-of-step snapshot, right after the function opening brace.
    #      v2 FIX 1: also snapshot the entry-year so the correction can compute
    #      the model's own within-call step (year now minus year at entry).
    text = insert_after_signature(
        text,
        "EDIT2a function signature",
        [
            "## v13.0 start-of-step snapshot for the BA net-increment anchor",
            ".k_ba <- 0.00007854",
            ".v130_d0_by_id <- stats::setNames(tree$dbh, tree$tree)",
            ".v130_ba0  <- sum(.k_ba * tree$dbh^2 * tree$expf, na.rm=TRUE)",
            ".v130_N0   <- sum(tree$expf, na.rm=TRUE)",
            ".v130_qmd0 <- if (isTRUE(.v130_N0 > 0)) sqrt(sum(tree$dbh^2 * tree$expf, na.rm=TRUE) / .v130_N0) else NA_real_",
            ".v130_rd0  <- NA_real_",
            "## v2 FIX 1: entry-year snapshot. tree$year is the CUMULATIVE elapsed-year",
            "## counter (the harness increments it by one every call). The correction",
            "## must scale by the model's within-call clock advance, not the absolute",
            "## clock, so record year at entry and difference it at the correction point.",
            ".v130_year0 <- tryCatch(as.numeric(tree$year[1]), error=function(e) NA_real_)",
        ],
    )

    # (2b) capture rd0 while sdm_rd still exists, then drop the sdm_* columns.
    # UNCHANGED from v1 (net basis was already correct).
    text = replace_line(
        text,
        "EDIT2b sdm select drop",
        "dplyr::select(-sdm_sdimax, -sdm_sdi, -sdm_rd, -sdm_mfrac, -sdm_keepi, -sdm_keepc)",
        [
            "# v13.0: capture start-of-step RD proxy inside the pipe (anon fn + <<- to reach function scope) before dropping sdm_rd",
            "dplyr::mutate(.rd_tmp = sdm_rd) %>% (function(.df){ .v130_rd0 <<- stats::weighted.mean(.df$.rd_tmp, .df$expf, na.rm=TRUE); .df }) %>% dplyr::select(-sdm_sdimax, -sdm_sdi, -sdm_rd, -sdm_mfrac, -sdm_keepi, -sdm_keepc, -.rd_tmp)",
        ],
    )

    # (2c) BA net-increment correction, inserted just before the return select.
    #      v2 FIX 1: step from the within-call clock advance (= 1 per annual call).
    #      v2 FIX 2: tight single-year clamp [0.7, 1.5] and a bounded-nudge gain.
    text = insert_before_comment(
        text,
        "EDIT2c select return variables",
        "# select return variables",
        [
            "## v13.0 BA net-increment anchor (v2): scale ONLY survivor diameter increments so the",
            "## total end-of-step stand BA meets the v13.0 net anchor (ingrowth BA held fixed).",
            "## The exact quadratic solve makes the correction exact rather than a linear ratio.",
            "## .v130_rd0 uses the post-growth pre-mortality relative density as a one-year-step",
            "## proxy for start-of-step RD.",
            "if (is.finite(.v130_ba0) && .v130_ba0 > 0 && is.finite(.v130_qmd0) && .v130_qmd0 > 0 && is.finite(.v130_rd0) && isTRUE(.v130_N0 > 0)) {",
            "  ## v2 FIX 1: step is the model's OWN within-call clock advance (year now minus",
            "  ## year at entry), which is exactly 1 for the annual harness loop. The v1 builder",
            "  ## used .v130_step <- tree$year[1] (the ABSOLUTE clock), so on call k it demanded",
            "  ## tnet*k of net BA in a single one-year step and pinned the scale at its ceiling.",
            "  .v130_step <- tryCatch(as.numeric(tree$year[1]) - .v130_year0, error=function(e) 1)",
            "  if (!is.finite(.v130_step) || .v130_step <= 0) .v130_step <- 1",
            "  .v130_step <- min(1, .v130_step)   # one AcadianGYOneStand call advances the clock by one year",
            "  .v130_tnet <- 3.213247 - 0.00436607 * .v130_ba0 - 0.159089 * .v130_rd0 - 1.021738 * log(.v130_qmd0)",
            "  .v130_batar <- .v130_ba0 + .v130_tnet * .v130_step",
            "  .v130_isurv <- tree$tree %in% names(.v130_d0_by_id)",
            "  .v130_d0s <- as.numeric(.v130_d0_by_id[as.character(tree$tree[.v130_isurv])])",
            "  .v130_d1s <- tree$dbh[.v130_isurv]",
            "  .v130_e1s <- tree$expf[.v130_isurv]",
            "  .v130_dd  <- .v130_d1s - .v130_d0s",
            "  .v130_baing <- sum(.k_ba * tree$dbh[!.v130_isurv]^2 * tree$expf[!.v130_isurv], na.rm=TRUE)",
            "  .v130_A <- sum(.k_ba * .v130_e1s * .v130_d0s^2, na.rm=TRUE)",
            "  .v130_B <- sum(.k_ba * .v130_e1s * 2 * .v130_d0s * .v130_dd, na.rm=TRUE)",
            "  .v130_C <- sum(.k_ba * .v130_e1s * .v130_dd^2, na.rm=TRUE)",
            "  .v130_Tsurv <- .v130_batar - .v130_baing",
            "  .v130_s <- 1",
            "  if (is.finite(.v130_C) && .v130_C > 1e-12) {",
            "    .v130_disc <- .v130_B^2 - 4*.v130_C*(.v130_A - .v130_Tsurv)",
            "    if (is.finite(.v130_disc) && .v130_disc >= 0) .v130_s <- (-.v130_B + sqrt(.v130_disc)) / (2*.v130_C)",
            "  } else if (is.finite(.v130_B) && abs(.v130_B) > 1e-12) {",
            "    .v130_s <- (.v130_Tsurv - .v130_A) / .v130_B",
            "  }",
            "  if (!is.finite(.v130_s)) .v130_s <- 1",
            "  ## v2 FIX 2: bounded nudge, not an unbounded exact match. gain in [0,1] damps the",
            "  ## solved scale toward 1 (1 = exact per-year match, now safe with the corrected step;",
            "  ## ~0.5 hedges the near-asymptotic anchor-transfer risk on mature NB). The tight",
            "  ## [0.7,1.5] band is the sane range for a SINGLE-year survivor-increment scale and",
            "  ## blocks any residual runaway; v1's [0.25,4] was far too loose.",
            "  .v130_gain <- tryCatch(if (exists('ops') && !is.null(ops$ba.anchor.gain) && !is.na(ops$ba.anchor.gain)) as.numeric(ops$ba.anchor.gain) else 1, error=function(e) 1)",
            "  if (!is.finite(.v130_gain)) .v130_gain <- 1",
            "  .v130_gain <- min(1, max(0, .v130_gain))",
            "  .v130_s <- 1 + .v130_gain * (.v130_s - 1)",
            "  .v130_s <- min(1.5, max(0.7, .v130_s))",
            "  tree$dbh[.v130_isurv] <- .v130_d0s + .v130_dd * .v130_s",
            "}",
            "",
        ],
    )

    # ---------------------------------------------------------------------
    # Light syntactic sanity check on the assembled text.
    # ---------------------------------------------------------------------
    ba0_assigns = len(re.findall(r"\.v130_ba0\s*<-", text))
    year0_assigns = len(re.findall(r"\.v130_year0\s*<-", text))
    # The v1 absolute-clock step must be gone; the v2 within-call difference must be present.
    v1_step_gone = ".v130_step <- tryCatch(as.numeric(tree$year[1]), error=function(e) 1)" not in text
    v2_step_present = "as.numeric(tree$year[1]) - .v130_year0" in text
    # AcadianGYOneStand legitimately appears many times; require its presence.
    fn_present = len(re.findall(r"AcadianGYOneStand", text))
    lines_grew = text.count("\n") > original.count("\n")
    # Height guard: this BA-only build must NOT contain the old height-swap tokens.
    no_height_edit = (".Amax" not in text) and ("v13.0 M2 monomolecular anchor" not in text)
    # Loose-clamp guard: the v1 [0.25, 4] survivor band must not survive.
    no_loose_clamp = "min(4, max(0.25, .v130_s))" not in text

    if (ba0_assigns != 1 or year0_assigns != 1 or not v1_step_gone or not v2_step_present
            or fn_present < 1 or not lines_grew or not no_height_edit or not no_loose_clamp):
        print(
            "SANITY ERROR: .v130_ba0={}, .v130_year0={}, v1_step_gone={}, v2_step_present={}, "
            "AcadianGYOneStand refs={}, lines_grew={}, no_height_edit={}, no_loose_clamp={}".format(
                ba0_assigns, year0_assigns, v1_step_gone, v2_step_present,
                fn_present, lines_grew, no_height_edit, no_loose_clamp
            )
        )
        sys.exit(3)

    # ---------------------------------------------------------------------
    # All anchors matched and sanity passed: write output and show the diff.
    # ---------------------------------------------------------------------
    with open(out, "w") as fh:
        fh.write(text)

    diff = difflib.unified_diff(
        original.splitlines(keepends=True),
        text.splitlines(keepends=True),
        fromfile=os.path.basename(inp),
        tofile=os.path.basename(out),
        n=3,
    )
    sys.stdout.writelines(diff)
    if not text.endswith("\n"):
        sys.stdout.write("\n")

    print("BUILD_V130_BAONLY_V2_OK")


if __name__ == "__main__":
    main()
