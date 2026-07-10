#!/usr/bin/env python3
# build_v130_baonly.py
#
# Phase 2 BA-only builder. Transforms the FROZEN base AcadianGY_12.10.1.r into
# AcadianGY_13.0.r by applying ONLY the validated basal-area net-increment
# anchor (EDIT2a/2b/2c). The v13.0 dominant-height correction is NO LONGER a
# model-file edit: it is delivered through the harness-native ops$esi.anchor.coef
# hook (see fit_v130_esi_anchor.R and bench_parity_v130.R), so the WRONG height
# edits (the old EDIT1a-d, which patched the dead ops$use.esi.domht
# Chapman-Richards block) are REMOVED here.
#
#   EDIT 2  add a start-of-step snapshot plus a BA net-increment anchor that scales
#           only survivor diameter increments via an exact quadratic solve.
#
# The BA half is independent of the height hook and carries over UNCHANGED from
# build_v130.py, including the fail-loud anchor guards: this does NOT rewrite the
# file. It reads the source, applies each edit as a regex substitution that MUST
# match its anchor exactly once, and writes the result. If any anchor is found
# zero times or more than once, it prints an ANCHOR ERROR and exits(2) WITHOUT
# writing output, so a mis-match is caught rather than silently mis-applied.
#
# Default input  ~/_scripts/AcadianGY_12.10.1.r  (the frozen operational base)
# Default output ~/AcadianGY_13.0.r
#
# COLUMN CASING ASSUMPTION: the inserted R blocks assume lowercase tree-list
# columns (dbh, expf, tree, ht, year, cr, hcb), consistent with bench_parity's
# tree list (year, plot, tree, sp, dbh, ht, expf) and the height-block code in
# this function. If the build uses uppercase columns, adjust the casing in the
# two inserted blocks below before running.
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
    # NOTE: EDIT 1 (the dominant-height Chapman-Richards swap, old EDIT1a-d) is
    # INTENTIONALLY OMITTED. The v13.0 height correction is applied at runtime
    # through ops$use.esi.anchor.recal + ops$esi.anchor.coef in the harness
    # (bench_parity_v130.R reading ~/v130_esi_anchor_coef.csv). No height edit
    # to the model file.
    # ---------------------------------------------------------------------

    # ---------------------------------------------------------------------
    # EDIT 2: BA net-increment anchor. Carried over UNCHANGED (validated).
    # ---------------------------------------------------------------------

    # (2a) start-of-step snapshot, right after the function opening brace.
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
        ],
    )

    # (2b) capture rd0 while sdm_rd still exists, then drop the sdm_* columns.
    # The mortality pipeline is a magrittr chain, so the value is stashed to the
    # function environment via <<- inside an anonymous-function-in-pipe step. This
    # is the form recommended by the patch spec; it assumes the drop happens in a
    # %>% chain (the standard dplyr idiom in this function).
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
    text = insert_before_comment(
        text,
        "EDIT2c select return variables",
        "# select return variables",
        [
            "## v13.0 BA net-increment anchor: scale ONLY survivor diameter increments so the",
            "## total end-of-step stand BA meets the v13.0 net anchor (ingrowth BA held fixed).",
            "## The exact quadratic solve makes the correction exact rather than a linear ratio.",
            "## .v130_rd0 uses the post-growth pre-mortality relative density as a one-year-step",
            "## proxy for start-of-step RD.",
            "if (is.finite(.v130_ba0) && .v130_ba0 > 0 && is.finite(.v130_qmd0) && .v130_qmd0 > 0 && is.finite(.v130_rd0) && isTRUE(.v130_N0 > 0)) {",
            "  .v130_step <- tryCatch(as.numeric(tree$year[1]), error=function(e) 1); if (!is.finite(.v130_step) || .v130_step < 1) .v130_step <- 1",
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
            "  .v130_s <- min(4, max(0.25, .v130_s))",
            "  tree$dbh[.v130_isurv] <- .v130_d0s + .v130_dd * .v130_s",
            "}",
            "",
        ],
    )

    # ---------------------------------------------------------------------
    # Light syntactic sanity check on the assembled text.
    # ---------------------------------------------------------------------
    ba0_assigns = len(re.findall(r"\.v130_ba0\s*<-", text))
    # AcadianGYOneStand legitimately appears many times (definition, calls,
    # comments); require its presence rather than a single occurrence.
    fn_present = len(re.findall(r"AcadianGYOneStand", text))
    lines_grew = text.count("\n") > original.count("\n")
    # Height guard: this BA-only build must NOT contain the old height-swap tokens.
    no_height_edit = (".Amax" not in text) and ("v13.0 M2 monomolecular anchor" not in text)

    if ba0_assigns != 1 or fn_present < 1 or not lines_grew or not no_height_edit:
        print(
            "SANITY ERROR: .v130_ba0 assignments={}, AcadianGYOneStand refs={}, lines_grew={}, no_height_edit={}".format(
                ba0_assigns, fn_present, lines_grew, no_height_edit
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

    print("BUILD_V130_BAONLY_OK")


if __name__ == "__main__":
    main()
