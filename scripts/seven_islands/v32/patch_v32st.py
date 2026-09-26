# patch_v32st.py, September 26, 2026. Folds the v32 stress test into the v32 sources. Replaces four
# v32 sentences (all written September 23, none carried from v29) that the stress test withdraws,
# and inserts new material. Every replacement is listed in content-inventory-diff_v32-to-v32r26.md.
import io, re, sys
B = sys.argv[1] if len(sys.argv) > 1 else "/home/aaron/jobs/silc_v32_docbuild/"
T = B + "v32st/text/"
rd = lambda p: io.open(p, encoding="utf-8").read()
def pat(old):  # whitespace-insensitive literal
    return re.compile(r"\s+".join(re.escape(w) for w in old.split()))
def rep(s, old, new, tag):
    p = pat(old); n = len(p.findall(s)); assert n == 1, "%s: anchor count %d" % (tag, n)
    return p.sub(lambda m: new, s, count=1)
def ins_after(s, old, new, tag):
    p = pat(old); ms = list(p.finditer(s)); assert len(ms) == 1, "%s: anchor count %d" % (tag, len(ms))
    e = ms[0].end(); return s[:e] + new + s[e:]
def ins_before(s, old, new, tag):
    p = pat(old); ms = list(p.finditer(s)); assert len(ms) == 1, "%s: anchor count %d" % (tag, len(ms))
    b = ms[0].start(); return s[:b] + new.rstrip('\n') + '\n\n' + s[b:]

# ------------------------------------------------------------------ report
s = rd(B + "v32_report_source.md")
s = rep(s, "v32, September 23, 2026, with the starting height factorial and AGM v8.40",
        "v32, September 23, 2026, with the starting height factorial and AGM v8.40, revised September 26, 2026 with a stress test", "R title")
s = rep(s, "From v32 the primary AGM row is v8.40, and AGM's remaining defect is basal area growth that runs about twice the observed rate.",
        "From v32 the primary AGM row is v8.40.", "R front defect")
s = ins_after(s, "Every v29 section, table, figure and number is carried unchanged and nothing is renumbered.*",
        "\n\n" + rd(T + "report_front.md").rstrip(), "R front add")
s = rep(s, "v32 September 23, 2026\n\n# Results and recommendation",
        "v32 September 23, 2026, revised September 26, 2026\n\n# Results and recommendation", "R date")
s = rep(s, "That is the cleaner reading of what is left of the AGM gap. AGM v8.40 grows basal area 95.2 percent faster than observed and underpredicts net stem loss by 78 percent, essentially what v8.36 did, so the late mortality onset identified in v26 remains AGM's genuine process defect.",
        "On all 65 plots AGM v8.40 grows basal area 95.2 percent faster than observed and misses 78 percent of the observed net change in stems, essentially what v8.36 did. The stress test at the end of this section shows that this reading does not survive the removal screen, and the September 23 statement that it is AGM's genuine process defect is withdrawn.", "R rate para")
s = rep(s, "and its remaining defect is a process one, basal area growth that runs about twice the observed rate because mortality starts too late.",
        "and once the removal plots are screened its basal area and volume increments track the observed rates as closely as any configuration in the roster (stress test below).", "R what changes")
s = ins_before(s, "\n## Recommendation\n\n*v32 note", "\n" + rd(T + "report_stresstest.md").rstrip() + "\n", "R stress section")
s = ins_after(s, "It inflated observed standing volume and therefore understated every configuration's volume bias in v26 through v28.",
        "\n\n" + rd(T + "report_corr3_note.md").rstrip(), "R corr3 note")
s = ins_before(s, "\n# What changed from v28\n", "\n" + rd(T + "report_changelog.md").rstrip() + "\n", "R changelog")
s = s.rstrip() + "\n\n" + rd(T + "report_reproduce.md").rstrip() + "\n"
io.open(B + "v32_report_source.md", "w", encoding="utf-8").write(s)

# ------------------------------------------------------------------ memo
m = rd(B + "v32_memo_source.md")
m = rep(m, "September 8, 2026, revised September 9 and September 16, 2026, v32 September 23, 2026\n",
        "September 8, 2026, revised September 9 and September 16, 2026, v32 September 23, 2026, revised September 26, 2026\n", "M date")
m = rep(m, "What remains of it is a process defect that neither treatment touches, since AGM v8.40 still grows basal area 95.2 percent faster than observed and underpredicts net stem loss by 78 percent, the late mortality onset first identified in v26.",
        "On all 65 plots AGM v8.40 still appears to grow basal area 95.2 percent faster than observed, but the stress test below shows that figure is driven by the removal plots and does not hold once they are screened.", "M defect")
m = ins_before(m, "\nThe draft pick is unchanged because every published FVS-ACD row already started from measured heights.",
        "\n" + rd(T + "memo_stresstest.md").rstrip() + "\n", "M stress")
io.open(B + "v32_memo_source.md", "w", encoding="utf-8").write(m)

# ------------------------------------------------------------------ deck
d = rd(B + "v32_deck_source.md")
d = rep(d, "## [48 | front] What remains of the AGM gap is BA growth",
        "## [48 | front] Screened, AGM tracks observed growth", "D title")
d = rep(d, "- Basal area increment ignores height and moves only a few points under either treatment\n- AGM v8.40 grows basal area 95% too fast and misses 78% of net stem loss, as v8.36 did\n- v29's AGM volume increment of +138% spanned a height basis change, matched basis +60%",
        "- On all 65 plots AGM v8.40 BA increment is +95%, but removals depress the observed rate\n- On the 51 screened plots AGM is -9.5% on BA and +0.7% on volume increment, closest of all\n- v29's AGM volume increment of +138% spanned a height basis change, matched basis +60%", "D bullets")
d = rep(d, "| Configuration | Heights | BA increment bias (%) | BA increment R² | Volume increment bias (%) | Net stem change bias (%) |\n| --- | --- | --- | --- | --- | --- |\n| AGM v8.36 | Dubbed | +90.0 | -0.134 | +138.1* | -78.4 |\n| AGM v8.40 | Measured | +95.2 | -0.146 | +59.8 | -78.3 |\n| FVS-ACD v13.1 hier | Measured | +69.0 | -0.073 | +58.2 | -111.2 |\n| FVS-ACD v14 L1 | Measured | +86.2 | -0.205 | +67.1 | -100.4 |\n| FVS-ACD v14 L2 | Measured | -32.6 | 0.020 | +9.1 | -168.0 |",
        rd(T + "deck_table48.md").rstrip(), "D table")
d = rep(d, "AGM's remaining defect is the late mortality onset identified in v26.",
        "Stress test, September 26: on the refined screen (n = 51, removal plots and 1133 out) observed BA increment is 0.2933 m² ha⁻¹ yr⁻¹ and observed stems rise by 2.95 trees ac⁻¹ yr⁻¹ through ingrowth. AGM v8.40 gains 0.55, and every FVS-ACD configuration shows a small net loss, so under-recruitment is common to the roster. The September 23 claim that AGM's remaining defect is BA growth is withdrawn. Source file v32st_rates_by_screen_DATA_2026-09-26.csv.", "D notes")
d = rep(d, "| Starting height basis | v32, AGM gap mostly heights, standardize and test a hybrid screen (slides 45 to 48) |",
        "| Starting height basis | v32, AGM gap mostly heights; repair 18 feet-recorded t1 heights (plots 1150, 1178), standardize, test a hybrid screen (slides 45 to 48) |", "D closing")
io.open(B + "v32_deck_source.md", "w", encoding="utf-8").write(d)
print("patched report, memo, deck")
