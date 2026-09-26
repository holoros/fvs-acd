# patch_v32st3.py, September 26, 2026. Aaron's decision: FVS-ACD 14.1 becomes the ten-year draft pick,
# replacing v14 L2; v13.1 hierarchical stays the long-horizon pick. Replaces the same-day "flagged, left
# open" sentences written earlier on September 26 and adds a superseding note at the head of the
# report and memo recommendations. Carried v29 recommendation text is kept as written. No em dashes.
import io, re, sys
B = sys.argv[1]; T = B + "v32st/pick/"
rd = lambda p: io.open(p, encoding="utf-8").read()
def pat(old): return re.compile(r"\s+".join(re.escape(w) for w in old.split()))
def rep(s, old, new, tag):
    ms = list(pat(old).finditer(s)); assert len(ms) == 1, "%s: %d" % (tag, len(ms)); return s[:ms[0].start()] + new + s[ms[0].end():]
def ins_before(s, old, new, tag):
    ms = list(pat(old).finditer(s)); assert len(ms) == 1, "%s: %d" % (tag, len(ms)); b = ms[0].start(); return s[:b] + new.rstrip("\n") + "\n\n" + s[b:]
note = rd(T + "rec_note.md")
s = rd(B + "v32_report_source.md")
s = rep(s, "scorecard flatters it, and the draft pick of v14 L2 is flagged for restatement on the screened basis.*",
        "scorecard flatters it. On September 26 14.1 replaced v14 L2 as the ten-year draft pick, with that under growth stated as its limitation.*", "R front")
s = rep(s, "The v29 draft pick of v14 L2 for ten-year accuracy rests on the all-plot scorecard, and whether it should be restated on the screened basis is an open decision for the next revision rather than a change made here.",
        "The v29 draft pick of v14 L2 for ten-year accuracy rested on the all-plot scorecard. On September 26 14.1, the current release, replaced it as the ten-year draft pick, with the under growth above stated as its limitation; the note at the head of the Recommendation gives the terms.", "R section")
s = ins_before(s, "*v32 note, September 23, 2026. The starting height factorial leaves this recommendation as it stands,", note, "R rec note")
s = rep(s, "entry, and changes nothing already printed.",
        "entry, and changes nothing already printed. A third September 26 change records Aaron's decision that FVS-ACD 14.1 replaces v14 L2 as the ten-year draft pick: a note at the head of the Recommendation, and two same-day sentences that had left the pick open are replaced.", "R changelog")
io.open(B + "v32_report_source.md", "w", encoding="utf-8").write(s)
m = rd(B + "v32_memo_source.md")
m = rep(m, "Whether the v14 L2 draft pick should be restated on that basis is left open.",
        "On September 26 14.1 replaced v14 L2 as the ten-year draft pick, with that under growth stated as its limitation, and v13.1 hierarchical stays the long-horizon pick.", "M para")
m = ins_before(m, "The recommendation is stated as a band with a named draft pick, as in v28, and it now rests on", note, "M rec note")
io.open(B + "v32_memo_source.md", "w", encoding="utf-8").write(m)
d = rd(B + "v32_deck_source.md")
d = rep(d, "- Screened, 14.x grows basal area at under half the observed rate; v14 L2 pick flagged",
        "- 14.1 is now the ten-year draft pick; it under grows basal area on screened plots", "D 49")
d = rep(d, "- Draft pick confirmed, FVS-ACD v14 L2 ten-year, v13.1 hierarchical long-horizon",
        "- Draft pick, FVS-ACD 14.1 ten-year (September 26), v13.1 hierarchical long-horizon", "D closing bullet")
d = rep(d, "| FVS-ACD 14.1 | +2.7 points on every plot; 14.x under grows BA on screened plots; restate the v14 L2 pick on the screened basis? (slide 49) |",
        "| FVS-ACD 14.1 | ten-year draft pick from September 26; under grows BA on screened plots, 6.7 points below v13.1 there (slide 49) |", "D closing row")
d = rep(d, "- Draft pick on ten-year accuracy is FVS-ACD v14 L2, +3.5% bias and the roster's best R² at 0.306",
        "- v29 ten-year pick was FVS-ACD v14 L2 (+3.5%, R² 0.306); 14.1 replaces it from September 26", "D slide 3")
cut = d.index("## [1 | structure]")
d = d[:cut] + ("Revised a third time on September 26, 2026: FVS-ACD 14.1 becomes the ten-year draft pick. Slide 3's\n"
    "pick bullet and table row, slide 49's third bullet, and the closing slide's first bullet and 14.1 row are reworded. No slide\n"
    "added or removed.\n\n") + d[cut:]
d = rep(d, "| Ten-year accuracy | FVS-ACD v14 L2 | +3.5% bias, R² 0.306 |", "| Ten-year accuracy | FVS-ACD 14.1 (from Sept 26) | +6.6% bias, R² 0.287; -6.8% screened |", "D slide 3 table")
io.open(B + "v32_deck_source.md", "w", encoding="utf-8").write(d)
print("patched pick")
