# patch_v32st2.py, September 26, 2026. Adds the FVS-ACD 14.1 cells to the v32 sources as revised earlier
# on September 26 (backed up in _PREV_20260926b/). Insertion only, plus the deck renumbering of slides
# 49 to 74 to 50 to 75 with every slide cross reference shifted, as patch_v32.py did. No em dashes.
import io, re, sys
B = sys.argv[1]; T = B + "v32st/text141/"
rd = lambda p: io.open(p, encoding="utf-8").read()
def pat(old): return re.compile(r"\s+".join(re.escape(w) for w in old.split()))
def ins_after(s, old, new, tag):
    ms = list(pat(old).finditer(s)); assert len(ms) == 1, "%s: %d" % (tag, len(ms)); e = ms[0].end(); return s[:e] + new + s[e:]
def ins_before(s, old, new, tag):
    ms = list(pat(old).finditer(s)); assert len(ms) == 1, "%s: %d" % (tag, len(ms)); b = ms[0].start(); return s[:b] + new.rstrip("\n") + "\n\n" + s[b:]
s = rd(B + "v32_report_source.md")
s = ins_after(s, "lowers each measured height row by about 2 points of bias. No ranking changes.*", "\n\n" + rd(T + "report_front_v141.md").rstrip(), "R front")
s = ins_before(s, "\n## Recommendation\n\n*v32 note", rd(T + "report_v141.md"), "R section")
s = ins_after(s, "Table 22 is kept as printed, and nothing is removed or renumbered.", "\n\n" + rd(T + "report_changelog_v141.md").rstrip(), "R changelog")
s = s.rstrip() + "\n\n" + rd(T + "report_reproduce_v141.md").rstrip() + "\n"
io.open(B + "v32_report_source.md", "w", encoding="utf-8").write(s)
m = rd(B + "v32_memo_source.md")
m = ins_before(m, "\nThe draft pick is unchanged because every published FVS-ACD row already started from measured heights.", rd(T + "memo_v141.md"), "M")
io.open(B + "v32_memo_source.md", "w", encoding="utf-8").write(m)
d = rd(B + "v32_deck_source.md")
cut = d.index("## [1 | structure]"); pre, body = d[:cut], d[cut:]
def shift(n): n = int(n); return n if n <= 48 else n + 1
seq = re.compile(r'(slides?\s+)(\d+(?:(?:\s*,\s*|\s+and\s+|\s+through\s+|\s+to\s+)\d+)*)')
body = seq.sub(lambda mo: mo.group(1) + re.sub(r'\d+', lambda x: str(shift(x.group(0))), mo.group(2)), body)
for old in range(74, 48, -1):
    a = "## [%d | " % old; assert body.count(a) == 1, old; body = body.replace(a, "## [%d | " % (old + 1), 1)
a = "\n## [50 | front] Closing recommendation and next steps\n"; assert body.count(a) == 1
body = body.replace(a, "\n" + rd(T + "deck_slide_v141.md").rstrip() + "\n" + a, 1)
a = "| Questions for Carroll |"; assert body.count(a) == 1
body = body.replace(a, "| FVS-ACD 14.1 | +2.7 points on every plot; 14.x under grows BA on screened plots; restate the v14 L2 pick on the screened basis? (slide 49) |\n" + a, 1)
pre = pre + ("Revised again on September 26, 2026: one slide added (slide 49, FVS-ACD 14.1 on SILC) before the\n"
"closing recommendation, slides 49 through 74 renumbered 50 through 75 with every slide cross reference\n"
"in the slide body shifted by 1, and one closing open-item row added. Nothing removed. Slide count 75.\n\n")
io.open(B + "v32_deck_source.md", "w", encoding="utf-8").write(pre + body)
print("patched v141")
