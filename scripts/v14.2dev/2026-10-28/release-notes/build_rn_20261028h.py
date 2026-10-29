# Release notes revision h (28 October 2026), built on revision g (2026-10-27, md5 bb36f16a) by exact replacements, each asserted
# once, the same way revision g was built on f (build_rn_20261027g.py). Adds PREREG50 (bottom line, QC candidate entry, QC stems
# open item, reproducibility, summary row) and a paragraph on 14.3 PREREG3, 14.3 PREREG4 and the Howland decline diagnostic,
# with readings appended to the thinning and senescence open items. Removes nothing except the phrase "the commit after c2d79edd",
# which now names revision g's commit 5a638f9f. Every number in cfg_rn_h.json is copied from the RESULT r1 files (md5 e3c62336,
# 1ef7f471, ad9402e0, 178d7d14). Usage: python3 build_rn_20261028h.py G H cfg_rn_h.json. No em dashes.
import sys, json, hashlib
G, H, C = sys.argv[1], sys.argv[2], json.load(open(sys.argv[3], encoding="utf8"))
assert hashlib.md5(open(G, "rb").read()).hexdigest() == "bb36f16a764934ac0c80a3e5f801bb47", "base is not revision g"
t = open(G, encoding="utf8").read(); w0 = len(t.split())
def one(a, b):
    global t
    assert t.count(a) == 1, (t.count(a), a[:90]); t = t.replace(a, b)

one("release notes for PREREG16 to PREREG49 and the October 16 cross-version benchmark",
    "release notes for PREREG16 to PREREG50 and the October 16 cross-version benchmark")
one("Draft of October 27, 2026 (revision g, built on revision f of October 26, 2026)",
    "Draft of October 28, 2026 (revision h, built on revision g of October 27, 2026)")
one("so only the changes compare (`results/howland_20261026/`).\n",
    "so only the changes compare (`results/howland_20261026/`).\n\n" + C["bl_p50"] + "\n\n" + C["bl_143"] + "\n")
one("and the PREREG47 reading finds no QC arm read credible on the long run.",
    "and the PREREG47 reading finds no QC arm read credible on the long run." + C["cand_qc"])
one("the 14.3 track is ingrowth entry size and floor handling, and whether the QC scoring floor itself should be revisited.",
    "the 14.3 track is ingrowth entry size and floor handling, and whether the QC scoring floor itself should be revisited." + C["open_qc"])
one("(16 heavy stands, 68 of 108 on climate site index).",
    "(16 heavy stands, 68 of 108 on climate site index)." + C["open_thin"])
one("while the FIA curves peak only in spruce-fir (cross-version benchmark).",
    "while the FIA curves peak only in spruce-fir (cross-version benchmark)." + C["open_sen"])
one("revision g is in the commit after c2d79edd on the same branch.", C["commit_note"])
one("was registered after five server lookups and before any PREREG49 script.",
    "was registered after five server lookups and before any PREREG49 script." + C["repro_reg"])
t = t.rstrip("\n") + "\n" + C["row_p50"] + "\n"
assert chr(0x2014) not in t
open(H, "w", encoding="utf8").write(t)
print("words", w0, "->", len(t.split()))
