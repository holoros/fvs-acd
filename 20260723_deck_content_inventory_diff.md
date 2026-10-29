# Deck content-inventory diff: FVS-ACD_Hennigar_Aug2026.pptx

23 July 2026. Records the change from the prior deck version to the finalized one, per the
iterative-deliverable discipline (build on the prior version, no silent regression). No em dashes.

## Base and output
- Base (floor): FVS-ACD_Hennigar_Aug2026.pptx as of 06:58, 23 July 2026, 38 slides. Backed up as
  FVS-ACD_Hennigar_Aug2026_PREV_20260723.pptx before any edit.
- Output: same filename, 41 slides. Built by cloning the existing figure-plus-evidence layout
  (slide 16 family), so house style, master, and theme are inherited unchanged.

## Added (3 slides, inserted as new positions 34 to 36, after the Nova Scotia OSM head-to-head and
before Integrating Climate; this places the cross-cutting synthesis block at the end of the
Nova Scotia arc, matching GTR section order 10.8 then 10.9)

1. MASTER SCORECARD (new slide 34). Assertion title: "By determinant, OSM sweeps the managed and
   softwood cells; v12.11's clean wins are Nova Scotia hardwood, mixedwood, and the shorter
   horizons." Figure fig22_determinant_scorecard.png; numbers from master_scorecard.csv. Left column
   states the three honest determinant findings (OSM leads managed and softwood; v12.11's specific
   clean wins; base edges the single over-30-year NS cell; terciles unscored).
2. OVERALL RANKING (RECONCILED) (new slide 35). Assertion title: "Neither v12.11 nor OSM is a clean
   overall winner: v12.11 is the more consistent, OSM the more decisive where it wins." Figure
   fig23_overall_ranking.png; numbers from overall_ranking_summary.csv. Evidence carries the
   honest framing verbatim, including that the earlier v12.11-wins-overall headline was a
   triple-counted-NS artifact and is superseded, and that OSM has no score for two of eight
   ME/NB/QC sources. No "v12.11 wins overall" phrasing anywhere.
3. LONG-HORIZON BIOLOGICAL REALISM (new slide 36). Assertion title: "Over 160 years, v12.11 passes
   four of five Bakuzis relations; OSM flags Eichhorn and site ordering." Figure
   fig24_bakuzis_longterm.png; numbers from bakuzis_longterm.csv. Left column is the five-relation
   verdict matrix (Eichhorn, Reineke, site ordering, yield-density, Sukachev) with per-model
   PASS/FLAG, plus the net verdict framed as a falsification check read alongside the accuracy
   scorecard, not instead of it.

## Changed
- None. No existing slide's text, figure, table, or number was edited. The only structural change
  was inserting the three sldId entries and keeping Integrating Climate immediately after them.

## Removed
- Nothing. All 38 prior slides are carried forward intact (verified: every prior section eyebrow
  and assertion title still present in the 41-slide output via markitdown).

## Consistency checks
- Numbers on the three new slides cross-checked against the finalized report
  (FVS-ACD_v12.11_benchmark_report) and GTR sections 10.8 and 10.9, and against the source CSVs:
  master_scorecard.csv, overall_ranking_summary.csv, bakuzis_longterm.csv. Key values reproduced:
  NS hardwood 122.8 vs 165.2 vs 129.5; NS mixedwood 36.8 vs 46.3 vs 37.7; over-30-yr NS 49.8 (base)
  vs 52.4 (v12.11) vs 50.3 (OSM); mean rank with NS 1.56 (v12.11) vs 1.57 (OSM) vs 2.56 (base);
  Eichhorn CV 26.3% (OSM FLAG); OSM site-ordering 42 height / 105 volume inversions; plateau 31.6
  to 36.1 m2 ha-1.
- Validation: pptx validate.py --original PASSED. No placeholder text. Visual QA on all three new
  slides: assertion-evidence titles, CRSF palette (dark forest green 1A3D28 titles, moss 5E8C61
  eyebrows), superscript units rendered, no overflow or overlap.
- No em dashes; hyphenated ranges written as "to".

## Red-team pass (23 July, post-build) and the three fixes applied
An independent red-team subagent verified every number on the three new slides against the source
CSVs and the report/GTR (all trace cleanly, correct signs and winner attributions) and adversarially
tested the no-v12.12 call (holds). It surfaced three items, now fixed:

1. Slide 13 (CENTRAL RESULT) headline qualified, deliberate change, not silent. Was "On managed and
   mature stands, v12.11 beats OSM v2.26.1," which read as contradicting the new determinant slide
   (OSM sweeps the pooled managed cell). Now "On the managed and mature sources it targets, v12.11
   halves bias and beats OSM v2.26.1." True on the per-source bias the slide's own table shows
   (Baxter, CTRN, NB); no longer clashes with the pooled %RMSE cell. Slide 13's table and evidence
   are otherwise unchanged.
2. Slide 34 (master scorecard) bullet 1 tightened. Removed an ambiguous "in both regions" that could
   be read as OSM winning Nova Scotia mixedwood (it does not; that cell is v12.11's), and added a
   one-clause bridge to slide 13 (per-source bias vs pooled %RMSE are different lenses).
3. Slide 36 (Bakuzis) OSM caveat restored. Added the interpretive clause from the memo that OSM's
   Eichhorn and site-ordering flags come from real, previously disturbed SILC/CFI stands rather than
   a controlled synthetic gradient, so part may reflect stand history, not model behavior.

No numbers changed; all three fixes are wording/framing. Re-validated (validate.py PASSED) and
re-rendered; no overflow. v12.12 verdict on record and unchanged: no v12.12.

## Not duplicated
- v13.1 (hierarchical mortality and ingrowth refit) is in flight in a parallel session and is left
  to the existing Roadmap slide only. Recommendation on record and unchanged: no v12.12; fold Nova
  Scotia, especially its long CFI record, into the v13.1 fitting and benchmark set.
