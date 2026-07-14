#!/usr/bin/env python3
# =====================================================================
# patch_ascale_clamp.py
# FVS-ACD / AcadianGY v13.0 Phase 2 helper.
#
# Make the ascale clamp band inside calc_dht environment driven so the
# co-fit experiment can widen it at run time. The clamp currently pins
# ascale to the fixed band [0.85, 1.35]:
#
#     ascale = min(1.35, max(0.85, intercept + slope * ESI))
#   (or the equivalent two step form using pmin(1.35, ...) / pmax(0.85, ...))
#
# QC saturates the 1.35 ceiling, so QC dominant height cannot be pulled
# down further no matter what the anchor coefs do. This patcher rewrites
# ONLY that clamp so the ceiling becomes
#     as.numeric(Sys.getenv("ASCALE_HI","1.35"))
# and the floor becomes
#     as.numeric(Sys.getenv("ASCALE_LO","0.85"))
# leaving the default behaviour identical when the env vars are unset.
#
# It is deliberately paranoid: it locates the calc_dht function body first
# and operates ONLY inside it, requires exactly one matching ceiling and
# one matching floor (both anchored to a min/max clamp call, with the
# variable name ascale in the immediate neighbourhood), prints a unified
# diff of what it changed, and exits nonzero with a clear message if the
# clamp is not exactly the expected shape, so it can never silently
# mispatch a model file.
#
# CLI: python3 patch_ascale_clamp.py INPUT.r OUTPUT.r
#   default INPUT  ~/AcadianGY_13.0_v2.r
#   default OUTPUT ~/AcadianGY_13.0_wideclamp.r
#
# Aaron Weiskittel, CRSF. No em dashes.
# =====================================================================
import sys
import os
import re
import difflib

HI_ENV = 'as.numeric(Sys.getenv("ASCALE_HI","1.35"))'
LO_ENV = 'as.numeric(Sys.getenv("ASCALE_LO","0.85"))'

# Ceiling literal 1.35 as the first argument of a min()/pmin() call.
HI_RE = re.compile(r'(?P<pre>\b(?:min|pmin)\s*\(\s*)1\.35(?![0-9.])')
# Floor literal 0.85 as the first argument of a max()/pmax() call.
LO_RE = re.compile(r'(?P<pre>\b(?:max|pmax)\s*\(\s*)0\.85(?![0-9.])')

# How close (in characters) the ceiling and floor matches must sit to be
# considered part of the same ascale clamp, and how far to look for the
# variable name "ascale" around them.
PROXIMITY = 400
ASCALE_WINDOW = 200


def die(msg):
    sys.stderr.write("patch_ascale_clamp.py: FATAL: " + msg + "\n")
    sys.exit(2)


def find_function_body(text, fname):
    """Return (open_brace_index, past_close_brace_index) for the body of
    `fname <- function(...) { ... }`, skipping strings and comments while
    matching braces. Returns None if not found."""
    hdr = re.search(r'\b' + re.escape(fname) + r'\s*(?:<-|=)\s*function\b', text)
    if not hdr:
        return None
    i = text.find('{', hdr.end())
    if i == -1:
        return None
    depth = 0
    j = i
    in_str = None
    escaped = False
    n = len(text)
    while j < n:
        c = text[j]
        if in_str is not None:
            if escaped:
                escaped = False
            elif c == '\\':
                escaped = True
            elif c == in_str:
                in_str = None
        else:
            if c == '#':
                nl = text.find('\n', j)
                if nl == -1:
                    return None
                j = nl
                continue
            elif c == '"' or c == "'":
                in_str = c
            elif c == '{':
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0:
                    return (i, j + 1)
        j += 1
    return None


def main():
    argv = sys.argv[1:]
    inp = argv[0] if len(argv) >= 1 else "~/AcadianGY_13.0_v2.r"
    out = argv[1] if len(argv) >= 2 else "~/AcadianGY_13.0_wideclamp.r"
    inp = os.path.expanduser(inp)
    out = os.path.expanduser(out)

    if not os.path.isfile(inp):
        die("input model file not found: " + inp)

    with open(inp, "r") as fh:
        text = fh.read()

    span = find_function_body(text, "calc_dht")
    if span is None:
        die("could not locate the calc_dht function body in " + inp +
            " (expected 'calc_dht <- function(...) { ... }').")
    bstart, bend = span
    body = text[bstart:bend]

    hi_matches = list(HI_RE.finditer(body))
    lo_matches = list(LO_RE.finditer(body))

    if len(hi_matches) != 1 or len(lo_matches) != 1:
        die("expected exactly one ascale ceiling (min/pmin with 1.35) and one "
            "floor (max/pmax with 0.85) inside calc_dht, found "
            "%d ceiling and %d floor. Refusing to patch so nothing is "
            "silently mangled." % (len(hi_matches), len(lo_matches)))

    hi = hi_matches[0]
    lo = lo_matches[0]

    # The two clamp literals must sit close together (same clamp expression).
    lo_start = min(hi.start(), lo.start())
    hi_end = max(hi.end(), lo.end())
    if (hi_end - lo_start) > PROXIMITY:
        die("the 1.35 ceiling and 0.85 floor were found inside calc_dht but "
            "are %d characters apart (> %d); they do not look like one ascale "
            "clamp. Refusing to patch." % (hi_end - lo_start, PROXIMITY))

    # The variable name ascale must appear near the clamp, confirming this is
    # the ascale clamp and not some unrelated min/max on those literals.
    w0 = max(0, lo_start - ASCALE_WINDOW)
    w1 = min(len(body), hi_end + ASCALE_WINDOW)
    if "ascale" not in body[w0:w1]:
        die("found a min(1.35, ...) / max(0.85, ...) clamp inside calc_dht but "
            "the variable name 'ascale' does not appear within " +
            str(ASCALE_WINDOW) + " characters of it. Refusing to patch a clamp "
            "that may not be the ascale clamp.")

    # Perform the two replacements on the body. Replace the higher offset first
    # so the earlier offset stays valid.
    def repl(s, m, env_expr):
        return s[:m.start()] + m.group("pre") + env_expr + s[m.end():]

    ordered = sorted([(hi, HI_ENV), (lo, LO_ENV)], key=lambda t: t[0].start(),
                     reverse=True)
    new_body = body
    for m, env_expr in ordered:
        new_body = repl(new_body, m, env_expr)

    new_text = text[:bstart] + new_body + text[bend:]

    if new_text == text:
        die("replacement produced no change; the clamp may already be "
            "environment driven. Nothing written.")

    # Unified diff of just what changed.
    diff = difflib.unified_diff(
        text.splitlines(keepends=True),
        new_text.splitlines(keepends=True),
        fromfile=inp, tofile=out, n=2)
    diff_text = "".join(diff)
    sys.stdout.write("---- ascale clamp patch (inside calc_dht) ----\n")
    sys.stdout.write(diff_text)
    if not diff_text.endswith("\n"):
        sys.stdout.write("\n")

    with open(out, "w") as fh:
        fh.write(new_text)

    sys.stdout.write("\nwrote patched model: %s\n" % out)
    sys.stdout.write("ceiling 1.35 -> %s\n" % HI_ENV)
    sys.stdout.write("floor   0.85 -> %s\n" % LO_ENV)
    sys.stdout.write("clamp located inside calc_dht body at file offset %d..%d.\n"
                     % (bstart, bend))
    return 0


if __name__ == "__main__":
    sys.exit(main())
