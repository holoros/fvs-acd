# patch_v32st4.py, September 26, 2026. Value and merchantable volume view of the 14.1 pick, and the
# 14.1 implementation check. Insertion plus same-day replacements of text written earlier on September 26
# (the slide 49 block, the slide 3 basis cell, the closing 14.1 row). No em dashes.
import io, re, sys
B = sys.argv[1]; T = B + "v32st/p4/"
rd = lambda p: io.open(p, encoding="utf-8").read()
def pat(old): return re.compile(r"\s+".join(re.escape(w) for w in old.split()))
def rep(s, old, new, tag):
    ms = list(pat(old).finditer(s)); assert len(ms) == 1, "%s: %d" % (tag, len(ms)); return s[:ms[0].start()] + new + s[ms[0].end():]
def ins_before(s, old, new, tag):
    ms = list(pat(old).finditer(s)); assert len(ms) == 1, "%s: %d" % (tag, len(ms)); b = ms[0].start(); return s[:b] + new.rstrip("\n") + "\n\n" + s[b:]
NOTE_OLD = "(Tables 25 and 26), and v13.1 hierarchical stays the long-horizon pick."
NOTE_NEW = ("(Tables 25 to 27), and v13.1 hierarchical stays the long-horizon pick. On value and merchantable volume, "
            "the measures Seven Islands weighs most, 14.1 is the strongest FVS-ACD candidate on the 51 screened plots, "
            "with net merchantable volume 3.0 percent low (R² 0.638) and value 5.0 percent high (R² 0.630), against 10.8 "
            "percent high for both v13.1 hierarchical and AGM v8.40.")
s = rd(B + "v32_report_source.md")
s = ins_before(s, "## Recommendation\n\n*Draft pick, September 26, 2026.", rd(T + "report_vm.md"), "R vm")
s = rep(s, NOTE_OLD, NOTE_NEW, "R note")
s = rep(s, "A third September 26 change records Aaron's decision",
        "A fourth September 26 change adds the 14.1 implementation check and the value and merchantable volume view (Table 27) and restates the pick note on those measures. A third September 26 change records Aaron's decision", "R changelog")
io.open(B + "v32_report_source.md", "w", encoding="utf-8").write(s)
m = rd(B + "v32_memo_source.md")
m = ins_before(m, "\nThe draft pick is unchanged because every published FVS-ACD row already started from measured heights.", rd(T + "memo_vm.md"), "M vm")
m = rep(m, NOTE_OLD, NOTE_NEW, "M note")
io.open(B + "v32_memo_source.md", "w", encoding="utf-8").write(m)
d = rd(B + "v32_deck_source.md")
a = d.index("## [49 | front] FVS-ACD 14.1 on SILC"); b = d.index("\n## [50 | front] Closing recommendation and next steps")
d = d[:a] + rd(T + "deck49.md").rstrip() + "\n" + d[b:]
d = rep(d, "| Ten-year accuracy | FVS-ACD 14.1 (from Sept 26) | +6.6% bias, R² 0.287; -6.8% screened |",
        "| Ten-year accuracy | FVS-ACD 14.1 (from Sept 26) | screened value +5.0%, net merch -3.0% |", "D slide 3")
d = rep(d, "| FVS-ACD 14.1 | ten-year draft pick from September 26; under grows BA on screened plots, 6.7 points below v13.1 there (slide 49) |",
        "| FVS-ACD 14.1 | ten-year pick from September 26; best screened value (+5.0%) and net merch (-3.0%); under grows BA (slide 49) |", "D closing")
cut = d.index("## [1 | structure]")
d = d[:cut] + ("Revised a fourth time on September 26, 2026: slide 49 rebuilt around value and merchantable volume with\n"
    "the 14.1 implementation check, and slide 3's ten-year basis cell and the closing 14.1 row reworded. No slide\n"
    "added or removed.\n\n") + d[cut:]
io.open(B + "v32_deck_source.md", "w", encoding="utf-8").write(d)
print("patched p4")
