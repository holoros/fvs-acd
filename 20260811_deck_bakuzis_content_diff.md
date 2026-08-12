# Hennigar deck update, content inventory diff, 11 August 2026

Deck: FVS-ACD_Hennigar_Aug2026.pptx, Acadian G&Y Meeting, 18 August 2026.
Prior version backed up as FVS-ACD_Hennigar_Aug2026_PREV7_20260811.pptx (46 slides).
New version: 47 slides. Nothing removed.

## Added, one slide inserted at position 44, directly after SELF CORRECTION

| # | kicker | title claim | body words |
|---|---|---|---|
| 44 | V13.1 BAKUZIS ASSESSMENT | Two configurations fail biological realism; a narrower stack ships | 53 |

Sits under the 55 body word ceiling for a scientific talk, title at 9 words, longest single item at
16 words, and a speaker note at 375 words, well above the 2x body rule. Inserted between the existing
SELF CORRECTION slide (position 43) and the existing BENCHMARK INTEGRITY slide, which was previously
at position 44 and is now position 45. Only one slide was needed: the blocking results and the
shipping-subset recommendation fit together under the body ceiling as four numbered lines.

## Changed, one slide

**VERDICT AND KEY TAKEAWAYS (now slide 46, was slide 45).** Item 5 previously read "v13.1: bias
localized to diameter distribution, 60% of the gap still open". Now reads "v13.1 ships ingrowth 2.5x
plus r2, SDImax retained and retuned". Prior wording is preserved in the speaker note along with a
dated update paragraph (11 August 2026) that also names the two blocked configurations and points back
to the new Bakuzis slide for the full result. Items 1 through 4 are untouched. This slide's body word
count was already over the ceiling before this edit (flagged in the 6 August audit as one of five
pre-existing overages); the item 5 rewrite is two words shorter than what it replaced, so the edit
reduces rather than adds to that pre-existing condition.

ROADMAP (slide 39) and the four v13.1 slides from the 6 August pass (now slides 40 to 43) are untouched.

## Removed

Nothing. No slide, figure, table, number, or section was dropped.

## Numbers on the new slide and where each comes from

| claim | source |
|---|---|
| Blocks nosdi and full stack (ing3.9, all levers) from shipping | Bakuzis biological-realism testing on v13.1, p7bak/ |
| ing3.9 basal area drawdown 14.2% vs 3.0% base, ages 27 to 48, recovery delayed to 86 to 92 | bakuzis_FINAL_p7.csv (vetted, table itself unreachable this session) |
| ing3.9 apparent gain reverses sign: +14.9% at year 20, -2.9% at year 160 | bakuzis_FINAL_p7.csv, per NOTES.md (337 lines) |
| nosdi fails on level not slope: SDI 670 (base) to 1020 (nosdi) at age 160 | bakuzis_FINAL_p7.csv |
| nosdi basal area plateau 35 to 50 m² ha⁻¹, above the defensible envelope | bakuzis_FINAL_p7.csv |
| Shipping subset: ingrowth 2.5x plus r2 increment refit, SDImax retained, onset retuned 0.30 toward 0.55 to 0.60 relative density | NOTES.md, session-vetted recommendation |
| Secondary flag (note only, not on slide): base config Sukachev departure at age 160, ESI 20 carries +6.3% stems vs +1.6% basal area over ESI 12 | bakuzis_FINAL_p7.csv |

## Deliberately NOT put on the slide

The secondary Sukachev-relationship flag in the base configuration is carried in the speaker note only,
not on the slide face, since it is explicitly not a shipping blocker and the slide's four numbered lines
were already at the body word ceiling with the two blocking results and the shipping recommendation.

The full bakuzis_FINAL_p7.csv table lives on Cardinal and was not reachable from this sandbox session.
Every number on the slide and in its note is drawn from vetted session notes, not read directly off the
CSV. The speaker note states this provenance and caveat explicitly; nothing beyond the vetted numbers
was invented. The SDImax onset recalibration and its Bakuzis rerun are still open (tracked separately),
which the note also states.

## Verification performed

Density check run over the built file (47 slides) with the kicker indexed past, per the presentation
style skill. New slide 44 passes cleanly: body 53/55, title 9/12, longest paragraph 16/20, notes 375
words against a 106-word 2x-body floor. Slide 46 (VERDICT, formerly slide 45) is 1 word over the body
ceiling at 56; this is a pre-existing condition from before this edit, not introduced by it, and the
item 5 rewrite is 2 words shorter than the wording it replaced.

python-pptx schema and structural validation (`validate.py --original`) passed with no errors against
the prior deck as baseline.

Rendered visual pass done: LibreOffice to PDF, 47 pages, pages 43 to 46 rasterized at 110 dpi and
inspected directly. House style confirmed intact on the new slide: background 1A3D28, gold C5A55A
kicker "V13.1  BAKUZIS ASSESSMENT", Cambria 30pt white title claim (wraps cleanly to two lines), Calibri
17pt body in E7EEE4, gold numbered-circle motif matching slides 40 to 43 and 45. The m² ha⁻¹ unit in
item 3 renders as true Unicode superscript/subscript glyphs, not a caret or slash. Slide order confirmed
correct: 43 SELF CORRECTION, 44 BAKUZIS ASSESSMENT (new), 45 BENCHMARK INTEGRITY, 46 VERDICT AND KEY
TAKEAWAYS with the updated item 5.

FVS-ACD_Hennigar_Aug2026.pdf regenerated from the final 47-slide pptx; it had been stale since 6 August
at the 46-slide era.
