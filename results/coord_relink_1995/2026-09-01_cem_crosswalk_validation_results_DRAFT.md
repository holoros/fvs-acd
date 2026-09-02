# CEM crosswalk validation, results

*1 September 2026. Companion to `2026-09-01_1995_coordinate_relink_scoping_DRAFT.md`, which this
run corrects on one point before reporting results. Ran `cem_donor_match_2026-09-01.R` on Cardinal
against `ME_COND.csv` and `ME_TREE.csv`, with `REF_FOREST_TYPE.csv` and `REF_OWNGRPCD.csv` fetched
live from the USDA FIA datamart this session rather than reconstructed from memory. Full log at
`cem_run_2026-09-01.out`. No em dashes.*

## Correction to Section 4's matching scheme, caught while implementing it

Section 4 of the scoping doc proposed blocking each Master Stem plot on County plus coarsened
forest type, site tercile, size class, and ownership. That assumed the Master Stem plots carry
those attributes to match against. Section 1's own profile already showed they do not, the file is
County, Plot, SubPlot, Tree, Form, Risk only, and this was not caught until the match script was
actually written. A per-plot stratified donor match cannot run as Section 4 described it, since
there is nothing on the Master Stem side to coarsen except County. What ran instead is a
County-only exact block, with the forest-type, site, size, and ownership dimensions used to report
a within-county sensitivity range on the FIA side alone rather than to target a specific stratum
per plot. This is a real downgrade from Section 4's proposal, stated here rather than silently
patched around.

## Data

2,087 Master Stem tree rows (3 dropped for missing tree, form, or risk) across 83 plots in 15
Maine counties (all except Sagadahoc, matching Section 1). 21,661 forested FIA conditions
statewide (`COND_STATUS_CD == 1`), split 12,041 hardwood-group, 9,079 softwood-group, 445 mixed
(Oak/Pine, TYPGRPCD 400), 96 nonstocked, using the real TYPGRPCD groups from `REF_FOREST_TYPE.csv`
rather than an assumed FORTYPCD cutoff. Crosswalk applied to every live hardwood tree statewide
(`SPCD >= 300`, `STATUSCD == 1`), reproducing `apply_formrisk_crosswalk.R`'s `cw()` logic exactly,
same TREECLCD/grade/CULL_FLD/damage-code branches, same output codes.

## Two comparisons, and why one of them is not informative

Master Stem's Form and Risk codes were collapsed to the A/B and LR/HR convention stated in
`apply_formrisk_crosswalk.R`'s own header comment, the same one `ddbh_hw_mod` uses downstream,
A = {F1,F3,F4,F7}, B = {F2,F5,F6,F8}, LR = {R1,R2}, HR = {R3,R4}.

The risk comparison is not informative and should not be read as agreement. Master Stem's Risk
field observed only NHRI values 1 and 2 across all 2,087 rows (Section 1), both of which collapse
to LR, so `ms_pct_LR` is exactly 1.0000 in every county by construction, not because the crosswalk
and the field crew agree. The 2 to 4 percentage-point gap between that constant 1.0000 and the
crosswalk's own 96 to 98 percent LR rate is really just the crosswalk's HR (R3) rate on its own,
not a measured disagreement.

The form comparison is the real result. Statewide, tree-count-weighted, Master Stem's field-called
ideal-form rate is 80.35 percent against the crosswalk's damage-code-derived 85.37 percent, a 5.0
point gap, with the crosswalk reading more idealized than the field calls on average, though not
uniformly, three of the fifteen counties (Aroostook, Piscataquis, Washington) run the other way,
Master Stem higher than the crosswalk. County-level gaps range widely, from near parity in
Penobscot (county 19, 1.2 points, crosswalk higher) and Piscataquis (county 21, 1.2 points,
crosswalk lower) to a 31.5 point gap in Cumberland (county 5, Master Stem 58.7 percent against
crosswalk 90.2 percent) and a 20.5 point gap in Hancock (county 9, crosswalk higher).
Six of the fifteen counties fall within their own county by forest-type stratum range on the FIA
side (`pct_A_in_stratum_range` true, Aroostook, Franklin, Kennebec, Lincoln, Piscataquis,
Washington), meaning the gap there could plausibly be attributed to which forest-type stratum the
actual plot sits in rather than to a real crosswalk bias, which the missing Master Stem attributes
cannot rule out either way. The other nine, including Cumberland's 31.5 point gap and Hancock's
20.5, sit outside even the widest forest-type-stratified range the county's own FIA population
offers, which is harder to explain as stratum noise alone.

## What this does and does not show

This is a real, computed comparison, not a hypothetical one, and it is the first evidence outside
the FIA remeasurement population itself on whether the p37/p38 crosswalk's damage-code-derived form
call tracks a trained field observer's call. It is county-coarse rather than plot-matched, since
the missing Master Stem attributes rule out anything finer, and the two sources differ in year and
network (Master Stem 2017 CFRU/NHRI network plots, the crosswalk's FIA hardwood population spans
whatever remeasurement pairs exist statewide), so a gap is not proof of crosswalk error, and
agreement is not proof of crosswalk correctness. What it does support is a direction to check
further, the crosswalk reads more idealized than the field on average, with Cumberland and Hancock
as the two counties most worth a closer look if Aaron wants to pursue this. It does not touch p37's
adopted verdict, which rests on TOST equivalence in projection outcomes, not on this form-call
comparison, and nothing here argues for revisiting that verdict.

## Files

`cem_donor_match_2026-09-01.R` (the script), `cem_run_2026-09-01.out` (full log),
`cem_donor_pool_by_county_2026-09-01.csv`, `cem_donor_pool_by_county_fortyp_2026-09-01.csv`,
`cem_crosswalk_by_county_fortyp_2026-09-01.csv`, `cem_crosswalk_stratum_range_2026-09-01.csv`,
`cem_crosswalk_comparison_2026-09-01.csv` (the table above), `REF_FOREST_TYPE.csv`,
`REF_OWNGRPCD.csv` (both fetched live from the USDA FIA datamart, not from memory). All in
`results/coord_relink_1995/`.

## Open items

The true-coordinate path remains fully blocked on the 1995-era file and Aaron's go-ahead, unchanged.
If Aaron wants Cumberland and Hancock looked at more closely, the next step is pulling those
counties' Master Stem plots and FIA hardwood populations by hand to see whether the gap holds up
tree by tree rather than only in aggregate.
