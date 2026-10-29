# Implementation notes, Cardinal stress test, 12 August 2026

## Deviations
Ran five subagent tracks instead of the planned four: added Track E mid-run to merge Track B
(plot-level bootstrap) and Track C (corrected intervals) into one canonical number, since neither
alone was deck-ready and computing them separately would have left two inconsistent "improved"
composite scores in the repo. Decision to actually update deck headline numbers (versus footnote or
defer) was escalated to Aaron rather than assumed, since it changes numbers presented to OSM's own
developer six days out.

## Discovered unknowns
Table 30 / memat-medev "base" numbers circulating in prior handoffs are mislabeled: they come from
a v13.1-development baseline, not frozen v12.10.1. Not previously flagged anywhere in the repo.
OSM-ACD binary is present and previously used on this account, contradicting the deck's implicit
"external, can't run it here" framing for the Maine FIA subplot / QC MagPlot coverage gap.

## Failed repairs
None attempted and abandoned; Track D's two gap-closure attempts (memat/medev v12.11 scoring,
OSM-on-new-source scoring) were assessed as not completable within session time and reported as
open rather than forced.

## Deferred
Deck edit, PDF render, and rasterized visual pass: blocked by an unrecoverable Cowork sandbox
(scratch volume full) partway through the run. All source numbers, scripts, and the scoped list of
slide-level changes are written and verified; the edit itself is mechanical and low-risk once a
sandbox is available. Rebuilding the memat/medev raw FIA staging input and building a new OSM input
for Maine FIA subplot / QC MagPlot are both real, tractable follow-ups, not attempted this session.

---

DATA_STATE: verified against primary Cardinal plot metadata and per-stand harness output; no
fabricated numbers.
OUTCOME_VERIFICATION: Track E point estimates reproduce master_scorecard_sources.csv per-source
RMSE exactly; PEF weight correction identified as sole material driver and confirmed arithmetically.
FIREWALL: F9 applied throughout, every number re-derived from primary Cardinal files rather than
carried from prior memos; F8 applied to Track D's memat/medev repair attempt, which was not
credited until output could be checked, and was not completed.
PLAUSIBILITY_CHECK: PEF's weight jump (5.6x) against its outsized share of total stand-years is
the expected mechanism given its dominant n (2,853) and short-relative-to-Maine-FIA interval;
composite drop of 11-19 RMSE points is consistent with PEF's RMSE (14.7-18.0%) sitting far below
the composite average (70-107%).
UNKNOWNS_LEDGER: memat/medev raw staging input location [UNKNOWN], OSM input builder script
location [UNKNOWN], both logged in the report's Track D section.
LENGTH_CHECK: report measured against `20260811_weighted_composite_score.md` and
`20260811_final_scorecard_all_datasets.md` as prior artifacts of the same type; within their range.
IMPACT_UTILITY: replaces a headline number six days before an external stakeholder meeting with a
verified, tighter, and more defensible one; corrects a mislabeled base baseline before it could
propagate further.
NEXT_AUTONOMOUS_STEP: on sandbox recovery, apply the scoped deck edits (Overall Summary, Overall
Ranking Reconciled, memat/medev caveat, OSM framing, reproducibility line), back up the current
pptx with a _PREV_20260812 suffix first, render to PDF, rasterize, and visually inspect every
changed slide before calling it done.
