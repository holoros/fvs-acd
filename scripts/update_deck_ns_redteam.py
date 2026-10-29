#!/usr/bin/env python3
"""
Update FVS-ACD_Hennigar_Aug2026.pptx:
  - correct forest-group hardwood attribution (QC-artifact), top-height mechanism (dht.mult),
    Chapter-11 out-of-sample numbers, add red-team reframe 5, soften "fixed" language
  - swap in fixed data-footprint maps (fig20, fig20b, fig21)
  - add three new Nova Scotia slides
Source of truth: FVS-ACD_v12.11_benchmark_report.md (already corrected), redteam round-2 memo,
forestgroup attribution check, NS philosophy-pass memo + its CORRECTION section.
No em dashes anywhere in inserted text.
"""
import copy
from pptx import Presentation
from pptx.util import Emu, Inches, Pt
from pptx.enum.text import MSO_AUTO_SIZE
from pptx.oxml.ns import qn

ROOT = "/sessions/fervent-pensive-goodall/mnt/CRSF-Cowork/repos/fvs-acd"
SRC = f"{ROOT}/FVS-ACD_Hennigar_Aug2026.pptx"
OUT = f"{ROOT}/FVS-ACD_Hennigar_Aug2026.pptx"
FIG = f"{ROOT}/figures"

prs = Presentation(SRC)

# ---------------------------------------------------------------- helpers

def slide_by_1idx(i):
    return prs.slides[i - 1]

def set_run_text(shape_name, slide, new_text, run_index=0, para_index=0):
    """Replace the text of a single run, leaving its formatting untouched."""
    for shape in slide.shapes:
        if shape.name == shape_name and shape.has_text_frame:
            para = shape.text_frame.paragraphs[para_index]
            para.runs[run_index].text = new_text
            return True
    raise KeyError(f"shape {shape_name!r} not found")

def get_shape(slide, name):
    for shape in slide.shapes:
        if shape.name == name:
            return shape
    raise KeyError(name)

def replace_whole_paragraph_text(shape, para_index, new_text):
    """Collapse a paragraph's runs into the first run and set new_text, preserving that run's font."""
    para = shape.text_frame.paragraphs[para_index]
    runs = para.runs
    if not runs:
        return
    runs[0].text = new_text
    # remove any extra runs in this paragraph
    for r in runs[1:]:
        r._r.getparent().remove(r._r)

def replace_textbox_body(shape, new_text, keep_para0_only=True):
    """For a text frame whose paragraph 0 carries the body copy, replace it entirely."""
    tf = shape.text_frame
    replace_whole_paragraph_text(shape, 0, new_text)
    if keep_para0_only:
        for p in list(tf.paragraphs[1:]):
            p._p.getparent().remove(p._p)

def swap_picture(slide, shape_name, new_image_path, new_left=None, new_top=None,
                  new_width=None, new_height=None):
    old = get_shape(slide, shape_name)
    left = new_left if new_left is not None else old.left
    top = new_top if new_top is not None else old.top
    width = new_width if new_width is not None else old.width
    height = new_height if new_height is not None else old.height
    old_elem = old._element
    parent = old_elem.getparent()
    idx = list(parent).index(old_elem)
    parent.remove(old_elem)
    pic = slide.shapes.add_picture(new_image_path, left, top, width=width, height=height)
    # move new picture element to the same z-order slot as the old one
    new_elem = pic._element
    parent.remove(new_elem)
    parent.insert(idx, new_elem)
    return pic

def duplicate_slide(prs, index0):
    """Clone slide at 0-based index0, append at end, return new slide object."""
    source = prs.slides[index0]
    blank_layout = source.slide_layout
    dest = prs.slides.add_slide(blank_layout)
    # remove any placeholder shapes auto-added by the layout
    for shp in list(dest.shapes):
        shp._element.getparent().remove(shp._element)
    for shp in source.shapes:
        new_el = copy.deepcopy(shp._element)
        dest.shapes._spTree.append(new_el)
    # copy background / other slide-level formatting if present
    return dest

def move_slide(prs, old_index0, new_index0):
    xml_slides = prs.slides._sldIdLst
    slides = list(xml_slides)
    xml_slides.remove(slides[old_index0])
    xml_slides.insert(new_index0, slides[old_index0])

print("Loaded deck with", len(prs.slides.__iter__.__self__._sldIdLst), "slides")

# =============================================================================
# 1. SOFTEN "FIXED" LANGUAGE (redteam round 2, finding 15)
# =============================================================================

s1 = slide_by_1idx(1)
set_run_text("Text 0", s1, "FVS-ACD v12.11: the maturity-dependent bias, addressed")

s2 = slide_by_1idx(2)
set_run_text("Text 1", s2, "v12.10.1 ships; v12.11 addresses the bias that flips sign with maturity")

# =============================================================================
# 2. TOP-HEIGHT MECHANISM CORRECTION (redteam round 2, finding 2 / reframe 1)
#    esi.domht.afac / anchor-recalibration -> always-on per-province dht.mult scalar
# =============================================================================

s12 = slide_by_1idx(12)
tb7 = get_shape(s12, "TextBox 7")
replace_whole_paragraph_text(
    tb7, 0,
    "PASS on every guardrail. The TOPHT drift traces to the always-on per-province dht.mult "
    "height-increment scalar (NB_AFAC=0.579, QC_AFAC=0.111), not to the new growth levers and not "
    "to an ESI-consistent anchor-recalibration mechanism, which does not exist in this model file "
    "(next slide, red-team reframe). The lone Reineke flag is confined to the managed sensitivity "
    "check, just beyond the -1.8 to -1.4 band, and does not block the primary configuration. On the "
    "managed cell v12.11 ties OSM on bias but still trails on RMSE, though the gap narrowed from a "
    "9.4-point deficit under the base to 3.5 points."
)

s19 = slide_by_1idx(19)
set_run_text("TextBox 2", s19, "Three of six reframes with numeric or methods impact")
tb4 = get_shape(s19, "TextBox 4")
replace_whole_paragraph_text(
    tb4, 0,
    "Six lever configurations run through an identical stand gave bit-identical top height to three "
    "decimals (20.269 m) regardless of which levers were on. The ESI dominant-height anchor forces "
    "top height onto a curve driven by climate site index and age alone. A second-round check traced "
    "the drift to the always-on per-province dht.mult height-increment scalar (NB_AFAC=0.579, "
    "QC_AFAC=0.111), not to an ESI-consistent anchor-recalibration mechanism, which does not exist in "
    "this model file despite the harness still logging ANCHOR=TRUE."
)
tb9 = get_shape(s19, "TextBox 9")
replace_whole_paragraph_text(
    tb9, 0,
    "Independent verification reconfirmed byte-identical gate-off on a novel stand after every fix "
    "(max|Δdbh| = max|Δht| = max|Δexpf| = 0.000e+00). A fourth reframe corrects the "
    "hardwood forest-group causal story to a QC-source artifact (next section). A fifth confirms "
    "byte-identical gate-off a second time after a gated ESI-anchor height-cap re-clamp; it changes "
    "no number reported here. A sixth is Nova Scotia's pending long-interval result (later section)."
)

print("Section 1-2 (softened language, top-height correction) applied")

# =============================================================================
# 3. FOREST-GROUP HARDWOOD CORRECTION (redteam round 2, finding 4 / reframe 6;
#    forestgroup_attribution_check.md; report Section 6)
#    Keep fig18/fig19, fix takeaway titles and text.
# =============================================================================

s16 = slide_by_1idx(16)
set_run_text(
    "Text 1", s16,
    "Softwood is v12.11's clean win; the pooled hardwood shift is mostly a QC-source artifact"
)
t16_2 = get_shape(s16, "Text 2")
replace_whole_paragraph_text(
    t16_2, 0,
    "Pooled across all seven sources, softwood total-volume bias improves from -5.67% to -2.86% and "
    "basal-area bias from -9.00% to -5.45%, the narrowest gap to OSM (-1.43%, -3.21%) of the three "
    "forest groups. Mixedwood gains a smaller but real margin. Hardwood's pooled bias does widen "
    "(+2.82% to +5.42% total volume), but QC MagPlot alone drives roughly three-quarters of that "
    "shift, and QC's candidate-vs-base move is uniform across all three forest groups (+7.6 to +8.8 "
    "points in softwood, mixedwood, and hardwood alike), a pattern the hardwood-only Lever 4 cannot "
    "produce. With QC set aside, the true cross-source hardwood signal is small and mixed (base "
    "-0.77% to candidate +1.28%, n=347: Baxter, Maine FIA, PEF, SILC, New Brunswick), with three of "
    "five non-QC sources improving. n = 3,927 softwood, 1,365 mixedwood, 462 hardwood."
)

s17 = slide_by_1idx(17)
set_run_text(
    "Text 1", s17,
    "Precision tightens for softwood and mixedwood; hardwood is an open question, not a settled regression"
)
t17_2 = get_shape(s17, "Text 2")
replace_whole_paragraph_text(
    t17_2, 0,
    "Percent RMSE falls with the bias gains on softwood, 26.79% to 24.25%, and mixedwood, 39.46% to "
    "39.23%, though OSM keeps the tighter scatter on both, 21.08% and 33.61%. Hardwood ticks the "
    "wrong way on precision too, 53.06% to 54.12%, while OSM's precision is closer, 41.77%, even as "
    "its bias swings negative. This should not be read as a confirmed hardwood-specific v13.1 target: "
    "the bias-side decomposition shows the pooled hardwood shift is substantially a single-source (QC) "
    "artifact, not a genuine cross-source hardwood degradation, and the same province-assembly check "
    "has not yet been run against the precision numbers. Softwood remains this benchmark's clear win."
)

s18 = slide_by_1idx(18)
# Table 3: recompute hardwood row and the pooled all-forest-types row is unaffected in value,
# only the surrounding text changes; leave table numbers as-is (they are the correct source-verified
# figures already, per Table 6 of the report), just correct the narrative textbox.
tb8 = get_shape(s18, "TextBox 8")
replace_whole_paragraph_text(
    tb8, 0,
    "The all forest types row is a stand-weighted mean of the three rows above, computed from the "
    "forest group scorecard, not a separately scored pooled run. On that basis v12.11's overall bias, "
    "-2.66% total volume, is now close to OSM's -2.63%, but percent RMSE tells a different story: "
    "v12.11 pools to 30.21% against OSM's 25.39%. The hardwood row driving part of that RMSE gap is "
    "substantially a QC MagPlot artifact rather than a genuine hardwood-specific effect (previous "
    "slide); softwood and mixedwood carry the pooled row's real, source-consistent gains."
)

print("Section 3 (forest-group hardwood correction) applied")

# =============================================================================
# 4. CHAPTER-11 OUT-OF-SAMPLE NUMBERS (redteam round 2, finding 7)
#    Report Table 23 / Section 7.9 are source-verified: installation-out managed 0.9, PCT 1.5,
#    planted 4.0; province-out managed 1.5, PCT 4.1, planted 5.7; managed split-half 5.2.
#    Deck currently has stale figures (1.3 / 3.0 / 5.6). Fix table + prose, label the scheme.
# =============================================================================

s27 = slide_by_1idx(27)
t27_2 = get_shape(s27, "Text 2")
# this shape holds two paragraphs (design rationale, then the out-of-sample prose); only the
# third paragraph (index 2; index 1 is an empty spacer) carries the out-of-sample numbers that
# need correcting; the first paragraph (design rationale) is untouched.
para1 = t27_2.text_frame.paragraphs[2]
para1.runs[0].text = (
    "Out of sample it holds: managed mean absolute bias 0.9 installation-out and 1.5 province-out vs "
    "OSM's 8.3; planted beats OSM in every scheme (4.0 installation-out, 5.7 province-out, vs 16.7); "
    "PCT is 1.5 installation-out, 4.1 province-out (vs OSM's 3.7)."
)
t27_2.text_frame.auto_size = MSO_AUTO_SIZE.TEXT_TO_FIT_SHAPE

s29 = slide_by_1idx(29)
tbl29 = get_shape(s29, "Table 0").table
# rows: 0 header, 1 installation-out, 2 province-out, 3 split-half, 4 OSM reference
# cols: 0 scheme, 1 Planted, 2 PCT, 3 Managed
tbl29.cell(1, 1).text_frame.paragraphs[0].runs[0].text = "4.0"
tbl29.cell(1, 2).text_frame.paragraphs[0].runs[0].text = "1.5"
tbl29.cell(1, 3).text_frame.paragraphs[0].runs[0].text = "0.9"
tbl29.cell(2, 1).text_frame.paragraphs[0].runs[0].text = "5.7"
tbl29.cell(2, 2).text_frame.paragraphs[0].runs[0].text = "4.1"
tbl29.cell(2, 3).text_frame.paragraphs[0].runs[0].text = "1.5"
tbl29.cell(3, 3).text_frame.paragraphs[0].runs[0].text = "5.2"

text4 = get_shape(s29, "Text 4")
replace_whole_paragraph_text(
    text4, 1,
    "Managed is a clean out-of-sample win: 0.9 leave-one-installation-out and 1.5 "
    "leave-one-province-out vs OSM 8.3."
)
replace_whole_paragraph_text(
    text4, 2,
    "Planted is a robust win over OSM in every scheme (4.0 installation-out, 5.7 province-out, vs "
    "16.7) and transfers across the NB to QC border."
)
replace_whole_paragraph_text(
    text4, 3,
    "PCT is 1.5 leave-one-installation-out; it now transfers NB to QC at 4.1 leave-one-province-out "
    "(vs OSM 3.7), and the PCT basal-area residual closes. Quebec edge still reported as out of "
    "domain, conservatively."
)

text5 = get_shape(s29, "Text 5")
replace_whole_paragraph_text(
    text5, 0,
    "The robust additive re-fit removed the 1.6 clamp; fold coefficients now move with the data "
    "(planted basal-area release 3.6 to 4.1 across folds) and the out-of-sample numbers hold. "
    "In-sample class bias is near zero by construction, so the cross-validated numbers above are the "
    "evidence. These planted, PCT, and managed cross-validation results carry unchanged into v12.11: "
    "none of the five new levers touches the Chapter-11 direct-effect fit. Figures here are "
    "source-verified against the benchmark report (Table 23 and Section 7.9); the split-half figure "
    "is the managed scheme only, not run for planted or PCT."
)

print("Section 4 (Chapter-11 out-of-sample reconciliation) applied")

# =============================================================================
# 5. SWAP IN FIXED MAPS (fig20, fig20b, fig21) + NS-aware footprint headline
# =============================================================================

s5 = slide_by_1idx(5)
set_run_text(
    "Text 1", s5,
    "The v12.11 benchmark is Maine heavy, 87.3%, plus an independent Nova Scotia test"
)

# Picture 10 = fig20 footprint map. Old ratio 1.22, new fig20 ratio 1.354 (3900x2880).
# Keep the same vertical footprint (top=1.58, height=3.60) and same left edge, recompute width.
new_h = Inches(3.60)
new_w = Emu(int(new_h * (3900 / 2880)))
swap_picture(s5, "Picture 10", f"{FIG}/fig20_benchmark_footprint.png",
             new_left=Inches(1.75), new_top=Inches(1.58), new_width=new_w, new_height=new_h)

# Picture 11 = fig20b Maine inset. Old ratio 1.024, new ratio 1.024 (2580x2520), unchanged aspect.
swap_picture(s5, "Picture 11", f"{FIG}/fig20b_maine_inset.png",
             new_left=Inches(8.05), new_top=Inches(1.58), new_width=Inches(3.55), new_height=Inches(3.60))

# 5 stat cards: Maine, NB, QC, Nova Scotia (new), sources-count. Reflow from 4 to 5 across the
# same 0.60-12.70 span used by the original 4-card row.
card_w = Inches(2.26)
gap = Inches(0.155)
xs = [Inches(0.60) + i * (card_w + gap) for i in range(5)]

stat6 = get_shape(s5, "Stat 6")  # Maine
stat6.left, stat6.width = xs[0], card_w
stat7 = get_shape(s5, "Stat 7")  # New Brunswick
stat7.left, stat7.width = xs[1], card_w
stat8 = get_shape(s5, "Stat 8")  # Quebec
stat8.left, stat8.width = xs[2], card_w
stat9 = get_shape(s5, "Stat 9")  # was "sources across three jurisdictions" -> Nova Scotia card
stat9.left, stat9.width = xs[3], card_w
replace_whole_paragraph_text(stat9, 0, "4,504")
replace_whole_paragraph_text(stat9, 1, "Nova Scotia stands, managed and unmanaged (independent test)")

# duplicate stat9's shape for a 5th card: "8 sources across four jurisdictions"
stat9_elem = stat9._element
stat10_elem = copy.deepcopy(stat9_elem)
# rename via the XML nvSpPr/cNvPr name attribute before re-wrapping, so get_shape() can find it
cNvPr = stat10_elem.find('.//' + qn('p:cNvPr'))
cNvPr.set('name', 'Stat 10')
s5.shapes._spTree.append(stat10_elem)
stat10 = get_shape(s5, "Stat 10")
stat10.left, stat10.width = xs[4], card_w
replace_whole_paragraph_text(stat10, 0, "8")
replace_whole_paragraph_text(stat10, 1, "sources across four jurisdictions")

# Maine stat card wording gets "pooled" for clarity now that NS sits outside the pooled total
replace_whole_paragraph_text(stat6, 1, "Maine stands, 87.3% of the pooled ME/NB/QC total")

t9 = get_shape(s5, "Text 9")
replace_whole_paragraph_text(
    t9, 0,
    "The v12.11 candidate benchmark pools seven sources across Maine, New Brunswick, and Quebec into "
    "one three-way scored comparison, base, candidate, and OSM v2.26.1. Nova Scotia is evaluated "
    "separately as a fully independent, fourth-jurisdiction test (Nova Scotia section, later in this "
    "deck), never used to fit or tune any lever. Coordinates never released: true plot locations stay "
    "on the analysis cluster, aggregates only; Nova Scotia's PSP locations are additionally restricted "
    "under its own provincial data-license agreement."
)

# --- Slide 6: swap in fig21 (now 4-panel, wider aspect: 4080x1740, ratio 2.345) ---
s6 = slide_by_1idx(6)
new_h6 = Inches(3.05)
new_w6 = Emu(int(new_h6 * (4080 / 1740)))
new_left6 = Emu(int(Inches(0.60) + (Inches(12.10) - new_w6) / 2))
swap_picture(s6, "Picture 11", f"{FIG}/fig21_sample_sizes.png",
             new_left=new_left6, new_top=Inches(1.85), new_width=new_w6, new_height=new_h6)

tb5 = get_shape(s6, "TextBox 9")
replace_whole_paragraph_text(
    tb5, 0,
    "Figure. Stand counts by source, the seven ME/NB/QC sources scored in the forest-group and "
    "overall synthesis slides, plus Nova Scotia's independent managed/unmanaged split (4,504 stands, "
    "not pooled into the ME/NB/QC total)."
)
tb5.top = Inches(5.05)

tb6 = get_shape(s6, "TextBox 10")
replace_whole_paragraph_text(
    tb6, 0,
    "Maine's 5,021 stands split five ways: Penobscot Experimental Forest 2,853, CFRU CTRN 1,086, "
    "Maine FIA 918 at whole plot grain, Baxter State Park 91, and SILC Seven Islands 73. New "
    "Brunswick MagPlot adds 355 and Quebec MagPlot adds 378, completing the seven source, 5,754 "
    "stand pooled benchmark. Nova Scotia adds an eighth source and fourth jurisdiction, scored "
    "independently: 4,504 stands, 2,157 managed and 2,347 unmanaged."
)
tb6.top = Inches(5.45)
tb6.height = Inches(1.10)
tb6.text_frame.auto_size = MSO_AUTO_SIZE.TEXT_TO_FIT_SHAPE

t2_s6 = get_shape(s6, "Text 2")
t2_s6.top = Inches(6.60)
t2_s6.height = Inches(0.75)
t2_s6.text_frame.auto_size = MSO_AUTO_SIZE.TEXT_TO_FIT_SHAPE

print("Section 5 (map swaps + footprint headline) applied")

# =============================================================================
# 6. NOVA SCOTIA SLIDES (report Section 11; philosophy-pass memo + CORRECTION section)
#    Cloned from the ROADMAP slide's numbered-row layout (matching brand exactly).
#    Three slides: (A) managed levers generalize, (B) site index, (C) long-interval IN PROGRESS.
# =============================================================================

GREEN = "1A3D28"
AMBER = "C5773A"
roadmap_template = slide_by_1idx(32)  # captured before any inserts/moves

def fill_ns_row(slide, row, number, heading, heading_color, desc):
    """row in (1,2,3), matching the ROADMAP slide's shape-name numbering (4/9/14 etc.)."""
    num_name = {1: "Text 4", 2: "Text 9", 3: "Text 14"}[row]
    head_name = {1: "Text 5", 2: "Text 10", 3: "Text 15"}[row]
    desc_name = {1: "Text 6", 2: "Text 11", 3: "Text 16"}[row]
    replace_whole_paragraph_text(get_shape(slide, num_name), 0, number)
    head_shape = get_shape(slide, head_name)
    replace_whole_paragraph_text(head_shape, 0, heading)
    head_shape.text_frame.paragraphs[0].runs[0].font.color.rgb = __import__("pptx").dml.color.RGBColor.from_string(heading_color)
    desc_shape = get_shape(slide, desc_name)
    replace_whole_paragraph_text(desc_shape, 0, desc)

# ---- NS Slide A: managed levers generalize ----
nsA = duplicate_slide(prs, prs.slides.index(roadmap_template))
set_run_text("Text 0", nsA, "NOVA SCOTIA")
set_run_text("Text 1", nsA,
    "The managed-stand levers generalize to a fully independent province")
fill_ns_row(nsA, 1, "1",
    "4,504 scored pairs, entirely independent of everything else in this report",
    GREEN,
    "2,157 managed and 2,347 unmanaged stand-pairs from Nova Scotia's Permanent Sample Plot "
    "network, established 1965, the Acadian region's longest continuous forest-inventory record. "
    "Never used to fit or tune any v12.11 lever, any base-model coefficient, or the ESI site-index "
    "anchor: the cleanest available test of generalization.")
fill_ns_row(nsA, 2, "2",
    "Managed total-volume bias: -58.10% (base) to -42.32% (v12.11 candidate)",
    GREEN,
    "A 27% relative reduction, closely matching the size of the managed-stand improvement seen "
    "throughout the rest of this report on data the model was actually fit against. Lever 2's "
    "management gate is doing the same job here that it does on Maine, New Brunswick, and Quebec "
    "data.")
fill_ns_row(nsA, 3, "3",
    "Unmanaged bias: -6.04% to -6.07%, essentially untouched",
    GREEN,
    "Exactly the behavior Lever 2 is designed to produce: it acts only where a stand is flagged "
    "managed and leaves natural stands to the unmanaged self-thinning machinery. Softwood, "
    "mixedwood, and hardwood forest groups all improve under the candidate here; the overall NS "
    "bias remains large (-41.28% to -30.61%) because it is dominated by the managed subset's larger "
    "absolute gap, addressed on the next slide, not a forest-group or hardwood issue.")

# ---- NS Slide B: site index ----
nsB = duplicate_slide(prs, prs.slides.index(roadmap_template))
set_run_text("Text 0", nsB, "NOVA SCOTIA")
set_run_text("Text 1", nsB,
    "NS site index is measured correctly; most of the gap is real disturbance response, not a site-index artifact")
fill_ns_row(nsB, 1, "1",
    "Same basis, no species/base-age/unit bug",
    GREEN,
    "NS SITE_INDEX and its research-plot proxy AVGTOPHTM are dominant height in meters read at "
    "approximately breast-height age 50, the same basis documented for the model's own "
    "ESI-anchored dominant-height input. There is no mismatch on the NS side.")
fill_ns_row(nsB, 2, "2",
    "A transferability caveat: the QC/NB esi8 raster is +7.0 m biased (r=0.146)",
    AMBER,
    "The mismatch runs the other way. The QC/NB ESI v8 raster is independently documented (n = "
    "40,596 measured site-index records) to overstate true site index by +7.0 m with essentially no "
    "per-plot linear skill. The model's NB_AFAC=0.579 / QC_AFAC=0.111 height-growth anchor exists "
    "specifically to counteract that raster's inflation; NS gets no equivalent correction and is fed "
    "its real, uninflated field site index directly. Any future region relying on the same pathway "
    "inherits this same unproven, poorly constrained correction.")
fill_ns_row(nsB, 3, "3",
    "The correction is real but secondary, and tested on the unmanaged subset only",
    GREEN,
    "Re-scoring the unmanaged NS subset (n = 2,347) with a +7.0 m basis-matching adjustment moves "
    "total-volume bias from -6.04% to -4.84% (base) and -6.07% to -5.04% (v12.11), roughly a 15 to "
    "20% relative reduction of an already-small bias. Most of the large -58% managed / -41% overall "
    "under-prediction is NOT primarily a site-index artifact: it is dominated by real, short-term "
    "post-disturbance growth response. This finding is unmanaged-only; the much larger managed and "
    "overall biases were not rescored with corrected site index and should not be over-generalized.")

# ---- NS Slide C: long-interval, IN PROGRESS ----
nsC = duplicate_slide(prs, prs.slides.index(roadmap_template))
set_run_text("Text 0", nsC, "NOVA SCOTIA")
set_run_text("Text 1", nsC,
    "Long-interval test: in progress, no headline number yet")
fill_ns_row(nsC, 1, "1",
    "IN PROGRESS: a disturbance-screening bug was found and fixed",
    AMBER,
    "The tree-level cut-detection filter compared a string-typed status column against an integer "
    "constant, a comparison that is always false, so it silently passed every stand as undisturbed "
    "regardless of harvest history. Correcting it shows about 23% of the long-interval (over 30 "
    "year) bucket, the exact bucket that had produced an apparent bias sign flip, contained an "
    "undisclosed harvest inside the remeasurement interval.")
fill_ns_row(nsC, 2, "2",
    "The clean rescore is running (jobs 12536574 and 12536575)",
    AMBER,
    "The corrected, contamination-free pair set has been rebuilt and resubmitted through the "
    "identical, unmodified frozen harness used everywhere else in this report. Managed single-regime "
    "pairs are unaffected by the bug and do not need to be rerun.")
fill_ns_row(nsC, 3, "3",
    "The maturity-dependent sign-flip result is PENDING, not reported here",
    AMBER,
    "Nova Scotia's 1965-present record is the only Acadian source that can test a first-to-last, "
    "multi-decade trajectory independent of Maine, New Brunswick, and Quebec, directly probing "
    "whether the maturity-dependent, sign-flipping long-horizon volume pattern found elsewhere in "
    "this project reproduces on genuinely independent data. That test is in progress. No "
    "contaminated bias figure for the long-interval bucket is cited in this deck; the result will be "
    "reported once the corrected jobs complete.")

# Move the three new slides into place: right after the Chapter-11 out-of-sample slide (29),
# before INTEGRATING CLIMATE (originally slide 30). Source indices are the post-append positions.
n_before = 34  # slide count before these three appends
move_slide(prs, n_before, 29)
move_slide(prs, n_before + 1, 30)
move_slide(prs, n_before + 2, 31)

print("Section 6 (Nova Scotia slides) applied; total slides now",
      len(prs.slides._sldIdLst))

# =============================================================================
# 7. VERDICT SLIDE: add a fifth bullet on Nova Scotia (report Section 1 verdict
#    names it as one of three results new to this edition; the deck's closing summary
#    should not omit it now that three full NS slides exist).
# =============================================================================

s_verdict = slide_by_1idx(36)  # VERDICT, after the three NS-slide inserts shifted it from 33 to 36
shape8 = get_shape(s_verdict, "Shape 8")
text9 = get_shape(s_verdict, "Text 9")
shape8_elem = shape8._element
text9_elem = text9._element

new_shape_elem = copy.deepcopy(shape8_elem)
new_text_elem = copy.deepcopy(text9_elem)
s_verdict.shapes._spTree.append(new_shape_elem)
s_verdict.shapes._spTree.append(new_text_elem)

shapes_named_shape8 = [sh for sh in s_verdict.shapes if sh.name == "Shape 8"]
texts_named_text9 = [sh for sh in s_verdict.shapes if sh.name == "Text 9"]
new_bullet_dot = shapes_named_shape8[-1]
new_bullet_text = texts_named_text9[-1]

new_bullet_dot.top = Inches(6.65)
new_bullet_text.top = Inches(6.55)
new_bullet_text.height = Inches(0.85)
replace_whole_paragraph_text(
    new_bullet_text, 0,
    "This edition adds Nova Scotia, a fully independent province with the region's longest CFI "
    "record: the managed-stand levers generalize cleanly, the site-index question is answered "
    "honestly, and the long-interval maturity test is running, final numbers pending."
)
new_bullet_text.text_frame.auto_size = MSO_AUTO_SIZE.TEXT_TO_FIT_SHAPE

print("Section 7 (verdict slide NS bullet) applied")

prs.save(OUT)
print("Saved to", OUT)
