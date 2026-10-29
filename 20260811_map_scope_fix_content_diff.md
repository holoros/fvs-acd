# Content inventory diff: map scope fix, 11 August 2026

Scope: Aaron flagged that "the maps should show all benchmark datasets and not exclude Maine."
Two defects were confirmed by direct visual inspection and fixed in this pass, both isolated to
`FVS-ACD_Hennigar_Aug2026.pptx` and, for the second, one clause in `FVS-ACD_variant_overview_GTR_v1211.md`.
No results CSV, no Cardinal state, and no frozen number was touched.

## What was stale versus already correct

**Slide 5 (Data Footprint).** Both embedded pictures were stale, not one as first suspected.

- Large map (shape id 13, 959,853 bytes): embedded blob hash matched
  `figures/fig20_benchmark_footprint_PREVhex_20260723.png` exactly (md5 c044ff566812bffa4c7242b8c3e348ac).
  Swapped for the current `figures/fig20_benchmark_footprint.png` (md5 0faf273aeeaa916113f8a1e0d97c446b,
  983,109 bytes). Both versions actually include Maine correctly, so this was stale data, not a
  Maine-exclusion bug, but it had no business being in a live deck.
- Small inset map (shape id 14, 500,256 bytes): the task brief guessed this one might already be current.
  It was not. Its embedded blob hash matched `figures/fig20b_maine_inset_PREVhex_20260723.png` exactly
  (md5 325da859afecdfc45e36fba4c24d14f0). Swapped for the current `figures/fig20b_maine_inset.png`
  (md5 0306f1c7903cdebd96235c1e63f5ffc3, 494,866 bytes).

Both replacements used the delete-and-readd pattern (python-pptx has no in-place image swap), placed at
the exact original left/top/width/height. Post-save verification confirmed both new embedded images match
the current source files byte-for-byte.

**Figures fig12_data_locator.png and fig14_acadian_range.png.** Confirmed by direct visual inspection:
neither has Maine data hexes; both depict the legacy 705-stand New Brunswick and Quebec benchmark by
design, reproducing the original 2018 ECANUSA comparison. These are not stale and were not edited or
replaced; the images are correct for what they represent. The problem was disclosure in the surrounding
text, not the images.

## Wording added, and where

**Deck slides 21, 22, 23** (LEGACY VALIDATION, PRE-V12.11 / REGION OF EQUIVALENCE, LEGACY 705-STAND
BENCHMARK / OVERALL COMPOSITE, LEGACY 705-STAND BENCHMARK). None of the three previously stated on the
slide face or in notes that the underlying 705-stand set is New Brunswick and Quebec only. Added the
identical seven-word clause "New Brunswick and Quebec only, no Maine." to the slide body of all three
(as its own line on slides 21 and 22, appended to the last line on slide 23), and a fuller sentence to
each slide's speaker notes tying back to where the Maine-inclusive benchmark lives elsewhere in the deck
(slides 4 through 7 and 34 through 35). Ran the weiskittel-presentation-style density check after: all
three slides stayed under the 55-word scientific-talk body ceiling (40, 51, 50 words), no paragraph over
the 20-word cap, and notes stayed at least 2x body on every slide. No em dashes used.

**`FVS-ACD_variant_overview_GTR_v1211.md`, line 615-622 ("The honest scorecard position").** This was a
genuine factual defect, not just a missing caveat. The parenthetical describing the n=705 pooled scorecard
read "(MagPlot New Brunswick n=355 and ESI-covered Quebec n=350, plus recent Maine FIA for the
growing-stand cross-check)" — falsely implying Maine FIA stands feed into this specific 705-count
composite. They do not: 355+350=705 leaves no room for additional stands, and the "Maine FIA
growing-stand cross-check" is documented elsewhere in the same document (Section 10, lines 495-517) as an
explicitly independent, separate check used only during v12.9.0 mortality-gate development, on a
different stand set (n=788). Corrected the clause to read "(MagPlot New Brunswick n=355 and ESI-covered
Quebec n=350, New Brunswick and Quebec only, no Maine stands; the independent Maine FIA growing-stand
cross-check in Section 10 is a separate check on a different stand set and is not part of this pooled
n=705 scorecard)". No number, count, or result changed; only the composition claim was corrected.

**`FVS-ACD_v12.11_benchmark_report.md`.** Checked in full for "705." Every instance already discloses
New Brunswick and Quebec composition explicitly and correctly (Section 2 narrative, Figure 4 caption,
Section 7.2 "The independent in-domain evaluation set is MagPlot New Brunswick (n = 355) and ESI-covered
Quebec (n = 350), total n = 705"). No edit needed; nothing changed in this file.

**GTR figure caption at line 96-108 ("Geographic Range," Figure 14).** Reviewed and left unchanged. This
caption describes the model's fitted geographic applicability (Maine, New Hampshire, Vermont, New
Brunswick, Nova Scotia, Quebec, the region codes), a true and separate claim from benchmark stand
coverage. It does not present 705-stand composite or equivalence results, so it falls outside this fix's
scope per the task brief, and editing it risked conflating two legitimately different claims.

## Backups created

- `FVS-ACD_Hennigar_Aug2026_PREV9_20260811.pptx` (pre-edit full copy; PREV1 through PREV8 already existed)
- `FVS-ACD_variant_overview_GTR_v1211_PREV_20260811b.md` (pre-edit full copy; `_PREV_20260811` without the
  b-suffix was already used once today by an earlier, unrelated pass on this file)
- `FVS-ACD_v12.11_benchmark_report.md` was not edited, so no new backup was needed beyond the existing
  `_PREV_20260811` from the earlier pass today.

## Visual QA pass

Rendered the edited pptx to PDF via the proven soffice/HOME-redirect pattern (7 seconds, no ENOSPC
issues). Rasterized and visually inspected slide 5 and slides 21 through 23 at 110 dpi.

- Slide 5: both maps now show the current footprint, with Maine, New Brunswick, Quebec, and Nova Scotia
  all correctly represented (5,021 Maine stands of 5,754 pooled ME/NB/QC, 87.3%), matching the current
  source figures.
- Slides 21-23: the added "New Brunswick and Quebec only, no Maine." line/clause renders cleanly on each
  slide face, no overflow, no em dash, consistent with the deck's existing house style (Cambria title,
  Calibri body, sage/green palette).

PDF saved to `FVS-ACD_Hennigar_Aug2026.pdf` in the repo root. QA screenshots retained under the session
outputs folder (`qa2/pg5-05.png`, `qa2/pgleg-21.png`, `qa2/pgleg-22.png`, `qa2/pgleg-23.png`).
