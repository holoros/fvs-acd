# Content diff, FVS-ACD_Hennigar_Aug2026.pptx simplification, 15 August 2026 (second pass)

Base file: the 20-slide pass 18 deck, preserved in full as
`FVS-ACD_Hennigar_Aug2026_FULL_TECHNICAL_20260815.pptx`. Updated file: same main path, now 13
slides, simplified for the broad CFS audience and refocused on the FVS-ACD versus OSM comparison
with v13.1 (ship18) as a first-class scored model. The PDF was re-rendered alongside. Aaron's
request: simplify for a broad audience, focus on OSM vs FVS-ACD, especially v13.1. No em dashes.

## Removed slides (deliberate, all preserved in the FULL_TECHNICAL deck)

Seven slides moved out, none deleted from the record: release history table (old 3), five-lever
detail (old 6), validation guardrails (old 7), equivalence TOST (old 12), reconciled ranking (old
13), site productivity and climate (old 16), AI and productivity (old 18). Load-bearing content
from the cut slides was folded into surviving notes: the TOST verdicts, the NS slope question, and
the refreshed Table 34 dual-qualification numbers (OSM 21.6/81.9 vs v12.11 23.9/84.4) now live in
the Overall Summary notes; the reproducibility and open-integrity items were already in the
takeaways notes from pass 18. The title slide notes point the presenter at the FULL_TECHNICAL file.

## The new number on this deck: ship18's composite, computed this session

Cardinal job 13622727 (`results/p18osm/p19_composite_ship18.csv`, per-source
`p19_ship18_persource.csv`, observed basis verified identical across all four models including
corrected p18 Baxter). ship18 composite %RMSE: NS 85.44 [79.07, 91.98], NS-long 106.47 [99.44,
113.24]; bias -18.15 / -25.95. Reading: ship18 fixes its target (developing Maine FIA whole-plot,
bias -16.6 to -12.5, RMSE 38.7 to 37.0) and is otherwise essentially base; the composite ties base
because Nova Scotia dominates the stand-years weight and ship18 does not change NS. It trails
v12.11 (76.1 / 90.1) and OSM (72.1 / 89.1). One correction found on the way: the file previously
believed to be ship18's Baxter score (`v131ship_baxter_results.csv`) is actually the pre-pairing
configuration; the true ship18 Baxter is `p9lev3/p9_bax_ship18_results.csv` (28.80 %RMSE, +13.53
bias on the corrected basis). The pending-composite framing is now retired everywhere on the deck.

## Slide-level changes (new numbering)

Slide 1: title rewritten to "FVS-ACD and OSM, head to head across the Acadian region," subtitle
"Benchmark status, direct comparison, and the path to v13.1," verdict line extended with the v13.1
pointer. Slide 2: retitled "Two Acadian growth models, one shared benchmark"; the five agenda
chips now outline this talk (benchmark, head to head, maturity bias, Nova Scotia, v13.1) instead
of the working-group agenda topics. Slide 6 (Overall Summary): title now plain language ("OSM is
ahead, v12.11 is close, base is behind"); caption stripped of TOST/bootstrap jargon (detail moved
to notes). Slide 8 (v13.1 spotlight, was the four-way scorecard): retitled "v13.1 (ship18): fixes
its target gap; the overall composite still trails"; figure replaced with
`fig28_fourway_ship18.png` (true ship18 column, common corrected observed basis); card rewritten
in plain language with the composite, the Maine FIA gain, the NS-weight explanation, and both
disclosed tradeoffs. Slide 9 (Bakuzis): plain-language title ("Do the models stay biologically
sensible over 160 years?"). Slide 10 (Nova Scotia): title now carries the balanced reading.
Slide 11 (Roadmap): v13.1 card updated from "composite rerun pending" to the computed result.
Slide 12 (Takeaways): bullet 1 in plain language; bullet 3 adds ship18's narrowing of the
developing-end gap; bullet 5 replaces "composite pending" with the computed 85.4 / 106.5 result.
Slides 3, 4, 5, 7, 13 (footprint, problem, central result, master scorecard, questions) carry
forward from pass 18 unchanged.

## Verification

`validate.py --original` passes. Full 13-slide render to PDF and page-by-page raster inspection:
no overflow, no orphaned visuals from the deletions, ship18 figure matches on-slide text.
The pass 18 stale-figure disclosures (fig15 Baxter panel, fig22 pooled cells) carry forward
unchanged; the fig23 disclosure left with the ranking slide and its numbers now live in the
Overall Summary notes.
