#!/usr/bin/env python3
"""
Add the Nova Scotia OSM-ACD v2.26.1 head-to-head to FVS-ACD_Hennigar_Aug2026.pptx.

Adds one new NOVA SCOTIA slide (fourth in the section), cloned from the existing NS long-interval
slide so it matches house style exactly (same numbered-row layout, same GREEN/AMBER color logic).
Reports base vs v12.11 vs OSM v2.26.1 across the three points of comparison in
figures/_data/ns_headtohead.csv: managed stands (short and long interval), unmanaged stands (short and
long interval), and the over-30-year disturbance-clean bucket. States the honest, mixed read: v12.11 and
OSM tie on managed stands, OSM leads on short-interval unmanaged stands, v12.11 clearly wins at the
longest horizon. No existing slide content is changed; this is a pure addition.
Source of truth: figures/_data/ns_headtohead.csv, bench_ns_scorecard.csv, bench_ns_long_scorecard.csv.
No em dashes anywhere in inserted text.
"""
import copy
from pptx import Presentation
from pptx.oxml.ns import qn

ROOT = "/sessions/fervent-pensive-goodall/mnt/CRSF-Cowork/repos/fvs-acd"
SRC = f"{ROOT}/FVS-ACD_Hennigar_Aug2026.pptx"
OUT = f"{ROOT}/FVS-ACD_Hennigar_Aug2026.pptx"

prs = Presentation(SRC)

# ---------------------------------------------------------------- helpers (same pattern as
# scripts/update_deck_ns_redteam.py, reused for consistency)

def slide_by_1idx(i):
    return prs.slides[i - 1]

def set_run_text(shape_name, slide, new_text, run_index=0, para_index=0):
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
    para = shape.text_frame.paragraphs[para_index]
    runs = para.runs
    if not runs:
        return
    runs[0].text = new_text
    for r in runs[1:]:
        r._r.getparent().remove(r._r)

def duplicate_slide(prs, index0):
    source = prs.slides[index0]
    blank_layout = source.slide_layout
    dest = prs.slides.add_slide(blank_layout)
    for shp in list(dest.shapes):
        shp._element.getparent().remove(shp._element)
    for shp in source.shapes:
        new_el = copy.deepcopy(shp._element)
        dest.shapes._spTree.append(new_el)
    return dest

def move_slide(prs, old_index0, new_index0):
    xml_slides = prs.slides._sldIdLst
    slides = list(xml_slides)
    xml_slides.remove(slides[old_index0])
    xml_slides.insert(new_index0, slides[old_index0])

def fill_ns_row(slide, row, number, heading, heading_color, desc):
    num_name = {1: "Text 4", 2: "Text 9", 3: "Text 14"}[row]
    head_name = {1: "Text 5", 2: "Text 10", 3: "Text 15"}[row]
    desc_name = {1: "Text 6", 2: "Text 11", 3: "Text 16"}[row]
    replace_whole_paragraph_text(get_shape(slide, num_name), 0, number)
    head_shape = get_shape(slide, head_name)
    replace_whole_paragraph_text(head_shape, 0, heading)
    head_shape.text_frame.paragraphs[0].runs[0].font.color.rgb = __import__("pptx").dml.color.RGBColor.from_string(heading_color)
    desc_shape = get_shape(slide, desc_name)
    replace_whole_paragraph_text(desc_shape, 0, desc)

n_slides_before = len(prs.slides._sldIdLst)
print("Loaded deck with", n_slides_before, "slides")

# Verify the three existing NOVA SCOTIA slides are where expected (30, 31, 32) before templating
titles = []
for i, s in enumerate(prs.slides):
    for sh in s.shapes:
        if sh.has_text_frame and sh.text_frame.text.strip():
            titles.append(sh.text_frame.text.strip().split("\n")[0])
            break
ns_idx = [i for i, t in enumerate(titles) if t == "NOVA SCOTIA"]
print("NOVA SCOTIA slides at 0-index:", ns_idx, "(1-index:", [i + 1 for i in ns_idx], ")")
assert len(ns_idx) == 3, f"expected 3 existing NS slides, found {len(ns_idx)}"
template_idx0 = ns_idx[-1]  # clone the long-interval slide (most recently added, matches current style)

GREEN = "1A3D28"
AMBER = "C5773A"

# =============================================================================
# NEW NS SLIDE D: OSM-ACD v2.26.1 head-to-head
# =============================================================================

nsD = duplicate_slide(prs, template_idx0)
set_run_text("Text 0", nsD, "NOVA SCOTIA")
set_run_text(
    "Text 1", nsD,
    "OSM-ACD v2.26.1 head-to-head: a mixed, honest result, not a clean sweep"
)

fill_ns_row(
    nsD, 1,
    "1",
    "Managed stands: v12.11 and OSM are essentially tied",
    GREEN,
    "Short interval: base -58.10%, v12.11 -42.32%, OSM -41.96%, both candidates cutting the frozen "
    "base's bias by about 16 points. Long interval: base -74.36%, v12.11 -55.07%, OSM -57.40%, "
    "v12.11 modestly ahead. OSM is itself a native Acadian-zone model, so this is a faithful, "
    "apples-to-apples comparison, not a proxy."
)
fill_ns_row(
    nsD, 2,
    "2",
    "Unmanaged stands: OSM leads at short intervals, v12.11 at long",
    AMBER,
    "Short interval: base -6.04%, v12.11 -6.07%, OSM -2.58%, a genuine OSM advantage. Long interval: "
    "v12.11 -6.01%, OSM -6.86%, v12.11 slightly ahead. Neither model is uniformly better on unmanaged "
    "stands; the direction flips with interval length."
)
fill_ns_row(
    nsD, 3,
    "3",
    "Over 30 years: v12.11 holds bias near zero, OSM drifts to -9%",
    GREEN,
    "On the disturbance-clean, over-30-year bucket (n=903), Nova Scotia's longest independent record, "
    "total-volume bias is -1.66% for v12.11 against -9.14% for OSM, the clearest point of separation "
    "anywhere in this Nova Scotia validation. Consistent with the maturity-gated stand constraint "
    "(Lever 3b) doing real work at exactly the horizon it targets. Data: figures/_data/ns_headtohead.csv."
)

# Move the new slide to sit right after the third existing NOVA SCOTIA slide (template_idx0),
# before whatever follows it (INTEGRATING CLIMATE).
new_slide_pos_before_move = n_slides_before  # appended slide sits at the end pre-move
move_slide(prs, new_slide_pos_before_move, template_idx0 + 1)

print("Added NS OSM head-to-head slide; total slides now", len(prs.slides._sldIdLst))

prs.save(OUT)
print("Saved to", OUT)
