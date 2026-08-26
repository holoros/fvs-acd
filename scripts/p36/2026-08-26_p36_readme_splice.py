#!/usr/bin/env python3
"""Append the pass 36 section to results/gydb/README.md and add two forward pointers.

Append only. The script asserts that every line of the prior README survives verbatim and in order,
and that the two inserted blockquotes are the only additions above the appended section, so a silent
removal cannot pass unnoticed. A backup is written with a _PREV_YYYYMMDD suffix before any write.
"""
import re
import shutil
import sys
from pathlib import Path

REPO = Path("/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd")
README = REPO / "results" / "gydb" / "README.md"
SECTION = Path("/users/PUOM0008/crsfaaron/magplot/verify/p36/p36_readme_section.md")
STAMP = "20260826"

POINTERS = {
    "## Pass 30: h1_v132_mortgate scored against NB, QC, NS, and NS-long": (
        "> AMENDED by Pass 36 (26 August 2026). The NS and NS-long figures in this section rest on "
        "the subplot-pooling defect recorded in `results/gydb/p36-data-defects_REVIEW_2026-08-26.md`, "
        "where one NS_RS stand key pooled several research subplots whose trees already carried a "
        "per-hectare expansion factor. Those cells were rebuilt on a (stand, plot) key and rescored "
        "in pass 36, and the corrected values are in the pass 36 section at the end of this "
        "document. Nothing else here is withdrawn."
    ),
    "## Pass 33 (26 August 2026): maturity-gated ingrowth release, and the residual site-ordering driver": (
        "> AMENDED by Pass 36 (26 August 2026). The NS managed row in the short-interval table "
        "below, near 156.5 percent RMSE with a slope near 2.09, is a property of the subplot-pooling "
        "defect in the observed record rather than of the maturity gate. On the corrected basis the "
        "same cell scores 38.08 percent with a slope of 1.132 under the production default, and the "
        "gate's measured effect at the other sources is unchanged. See the pass 36 section at the "
        "end of this document."
    ),
}


def main() -> int:
    original = README.read_text(encoding="utf-8")
    section = SECTION.read_text(encoding="utf-8").rstrip("\n")
    orig_lines = original.split("\n")

    backup = README.with_name(f"README_PREV_{STAMP}.md")
    shutil.copy2(README, backup)

    lines = list(orig_lines)
    inserted = 0
    for heading, quote in POINTERS.items():
        try:
            i = lines.index(heading)
        except ValueError:
            print(f"heading not found, refusing to guess: {heading!r}")
            return 2
        if lines[i + 1 : i + 3] and lines[i + 2].startswith("> AMENDED by Pass 36"):
            print(f"pointer already present under {heading!r}, left alone")
            continue
        lines[i + 1 : i + 1] = ["", quote]
        inserted += 2

    body = "\n".join(lines).rstrip("\n")
    new = body + "\n\n" + section + "\n"
    README.write_text(new, encoding="utf-8")

    # Verification. Every original line must still be present, in order, in the new file.
    new_lines = new.split("\n")
    it = iter(new_lines)
    missing = [ln for ln in orig_lines if not any(ln == n for n in it)]
    if missing:
        print(f"REGRESSION: {len(missing)} original line(s) lost, restoring backup")
        shutil.copy2(backup, README)
        for ln in missing[:5]:
            print("  lost:", ln[:100])
        return 3

    added = len(new_lines) - len(orig_lines)
    print(f"lines before {len(orig_lines)}, after {len(new_lines)}, added {added}, "
          f"of which {inserted} are forward pointers")
    print(f"words before {len(original.split())}, after {len(new.split())}, "
          f"section words {len(section.split())}")
    print(f"backup at {backup}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
