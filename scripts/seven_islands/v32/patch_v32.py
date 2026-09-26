# patch_v32.py, September 23, 2026. Builds the v32 sources from the v29 revised September 16 sources
# by insertion only. Nothing is removed. Deck slides 45 to 70 are renumbered 49 to 74.
import io, re
B = "/home/aaron/jobs/silc_v32_docbuild/"
T = B + "v32text/"
rd = lambda p: io.open(p, encoding="utf-8").read()
def once(s, a):
    n = s.count(a); assert n == 1, "anchor count %d for %r" % (n, a[:70])

# ------------------------------------------------------------------ report
s = rd(B + "v32_report_source.md")
a = "Revised September 16, 2026 with the v29b equivalence rerun and the v14 self-thinning ablation\n"
once(s, a)
front = ("v32, September 23, 2026, with the starting height factorial and AGM v8.40\n\n"
"*v32, September 23, 2026. This release adds one analysis and changes the AGM verdict. Bruce\n"
"Carroll's AGM v8.40 delivery keeps the measured starting heights, where every earlier AGM delivery\n"
"replaced them with equation heights, and its gross volume bias falls from +33.4 to +15.1 percent with\n"
"R² rising from -0.285 to 0.151. FVS-ACD v13.1 hierarchical and both modes of v14 were rerun under\n"
"both treatments, and imputing every starting height adds 17.6 to 22.3 points of volume bias to each\n"
"of them. The measured reruns reproduce the published v29 rows byte for byte, so the draft pick is\n"
"unchanged. From v32 the primary AGM row is v8.40, and AGM's remaining defect is basal area growth\n"
"that runs about twice the observed rate. The new material is one section before the recommendation\n"
"with Tables 21 and 22 and Figures 46 and 47, one paragraph in the recommendation, a v32 changelog\n"
"section and a reproduce addendum. Every v29 section, table, figure and number is carried unchanged\n"
"and nothing is renumbered.*\n\n")
s = s.replace(a, a + "\n" + front, 1)
a = "September 8, 2026, revised September 9, 2026\n\n# Results and recommendation"
once(s, a)
s = s.replace(a, "September 8, 2026, revised September 9 and September 16, 2026, v32 September 23, 2026\n\n# Results and recommendation", 1)
a = "\n## Recommendation\n\n"
once(s, a)
rec = ("*v32 note, September 23, 2026. The starting height factorial leaves this recommendation as it\n"
"stands, because every FVS-ACD row it rests on already started from measured heights. It changes the\n"
"AGM statements that follow. AGM v8.40 with measured heights sits at +15.1 percent gross volume bias,\n"
"inside the FVS-ACD candidate range, and every AGM comparison below that uses v8.35 or v8.36 is on\n"
"the dubbed height basis and overstates AGM's volume by about 18 points. Every model in the strata\n"
"projections should start from the same height basis.*\n\n")
s = s.replace(a, "\n" + rd(T + "report_section.md").rstrip() + "\n" + a + rec, 1)
a = "\n# What changed from v28\n"
once(s, a)
chg = ("\n# What changed in v32\n\n"
"v32, September 23, 2026, is built on the v29 report as revised on September 16. It adds the starting\n"
"height factorial, which scores AGM v8.40 (Carroll, September 21, measured heights kept) against AGM\n"
"v8.36 (heights dubbed) and reruns FVS-ACD v13.1 hierarchical and FVS-ACD v14 L1 and L2 with measured\n"
"and with equation-imputed starting heights. The release is named v32 because v30 and v31 already\n"
"name the stratified scorecard and the model index folded into v29 on September 9. Added are one\n"
"results section with Tables 21 and 22 and Figures 46 and 47, a front matter paragraph, a note at the\n"
"head of the recommendation and a reproduce addendum. The primary AGM row becomes v8.40, and the v8.35\n"
"and v8.36 rows everywhere else in this report are retained as dated history on the dubbed height\n"
"basis. The AGM volume increment of +138.1 percent reported in v29 is now stated to span a change of\n"
"height basis, with +59.8 percent the matched figure for v8.40. No v29 number is changed and nothing\n"
"is removed or renumbered. Mortality and ingrowth decomposition, carbon flux, equivalence, the v30\n"
"stratified ranks, the v31 model index and the Bakuzis check were not rerun for the new cells.\n")
s = s.replace(a, chg + a, 1)
s = s.rstrip() + "\n\n" + (
"### v32, September 23, 2026\n\n"
"The FVS-ACD height factorial is SLURM array 14799757 on Cardinal, `silc_cfi/v32_htdub/run_htdub_factorial_v32.slurm`,\n"
"with the driver `bench_v32_htdub_treeout.R`, a copy of `v29_run/v14/bench_v14_silc_treeout.R` whose\n"
"only change is the `DUB_HT` switch, and model files `AcadianGY_13.1.r` (md5 5894df60) and\n"
"`v29_run/v14/AcadianGY_14.0.r` (md5 0d79723c) unchanged. AGM v8.40 was extracted on firebreather in\n"
"`jobs/silc_agm_v840/` with `export_fr_trees_final_v840.py` and `ingest_agm_v840_bystrata.R`, the\n"
"v8.36 scripts with file names changed. Scoring is job 14799832 (`score_v32ht.slurm`), running\n"
"`build_unified_treelist_v32ht.R`, `value_silcspec_v32ht.R` and `silc_cfi_rates_v32ht_SCRIPT_2026-09-23.R`,\n"
"each the v29b script with only paths, output names and configuration labels changed. Outputs are\n"
"`silc_cfi_v32ht_scorecard_primary_DATA_2026-09-23.csv`, its specification-literal twin, the byplot\n"
"files, `silc_cfi_rates_scorecard_v32ht_DATA_2026-09-23.csv` and\n"
"`silc_cfi_v32ht_height_diagnostic_DATA_2026-09-23.csv` from `diag_htdub.R`. The AGM trajectory\n"
"comparison is `agm_htdub_trajectory_compare.R` on Carroll's native `CFI_GrownDB_byStrata` (v8.36)\n"
"and `CFI_GrownDB_byStrata_noHTdub` (v8.40) tables, writing `agm_htdub_stand_year_DATA_2026-09-23.csv`\n"
"and `agm_htdub_trajectory_summary_DATA_2026-09-23.csv`. Figures 46 and 47 come from\n"
"`make_v32_figures.R`. No FIA coordinate enters any of these files.\n")
io.open(B + "v32_report_source.md", "w", encoding="utf-8").write(s)

# ------------------------------------------------------------------ memo
m = rd(B + "v32_memo_source.md")
a = "**SILC CFI benchmark v29 memo, metric restack and data repair**"
once(m, a)
m = m.replace(a, "**SILC CFI benchmark v32 memo, starting heights, metric restack and data repair**", 1)
a = "September 8, 2026, revised September 9 and September 16, 2026\n"
once(m, a)
m = m.replace(a, "September 8, 2026, revised September 9 and September 16, 2026, v32 September 23, 2026\n", 1)
a = "*Revised September 16, 2026. This revision withdraws"
once(m, a)
m = m.replace(a, ("\n*v32, September 23, 2026. This release adds the starting height factorial as its first section\n"
"with Table 9 and Figures 10 and 11. AGM v8.40 with measured heights becomes the primary AGM row, and\n"
"the draft pick is unchanged. Everything in the September 16 memo is carried unchanged.*\n\n") + a, 1)
a = "\n# The four corrections\n"
once(m, a)
m = m.replace(a, "\n" + rd(T + "memo_section.md").rstrip() + "\n" + a, 1)
io.open(B + "v32_memo_source.md", "w", encoding="utf-8").write(m)

# ------------------------------------------------------------------ deck
d = rd(B + "v32_deck_source.md")
cut = d.index("## [1 | structure]")
pre, body = d[:cut], d[cut:]
def shift(n):
    n = int(n); return n if n <= 44 else n + 4
seq = re.compile(r'(slides?\s+)(\d+(?:(?:\s*,\s*|\s+and\s+|\s+through\s+|\s+to\s+)\d+)*)')
def repl(mo):
    return mo.group(1) + re.sub(r'\d+', lambda x: str(shift(x.group(0))), mo.group(2))
body = seq.sub(repl, body)
for old in range(70, 44, -1):
    a = "## [%d | " % old
    assert body.count(a) == 1, old
    body = body.replace(a, "## [%d | " % (old + 4), 1)
a = "\n## [49 | front] Closing recommendation and next steps\n"
once(body, a)
body = body.replace(a, "\n" + rd(T + "deck_slides.md").rstrip() + "\n" + a, 1)
a = "| Questions for Carroll |"
once(body, a)
body = body.replace(a, "| Starting height basis | v32, AGM gap mostly heights, standardize and test a hybrid screen (slides 45 to 48) |\n" + a, 1)
a = "| v29 | September 8, 2026, revised September 9 and 16, 2026"
once(body, a)
body = body.replace(a, "| v32 | September 23, 2026, on v29 of September 8, 9 and 16", 1)
pre = pre + ("Revised September 23, 2026 as v32. Four new slides are added (slides 45 through 48) covering the\n"
"starting height factorial, AGM v8.40 with measured heights against v8.36 with dubbed heights, and\n"
"FVS-ACD v13.1 hierarchical and v14 L1 and L2 rerun with measured and with imputed starting heights.\n"
"v29 slides 45 through 70 are renumbered to v32 slides 49 through 74, a uniform shift of 4, and every\n"
"slide-number cross-reference inside slide bullets, tables and notes is updated. The closing slide\n"
"gains one open-item row and the title slide carries the v32 date. Nothing is removed. Slide count\n"
"moves from 70 to 74.\n\n")
io.open(B + "v32_deck_source.md", "w", encoding="utf-8").write(pre + body)
print("PATCH OK")
