# DRAFT, not registered: Bakuzis QC grid started from measured stand lists, 1.242 against 0.111 (PREREG44)

5 October 2026, draft for Aaron's review. Not registered, nothing run. It answers the open item of the QC close out note: the
PREREG31 and PREREG41 grids start from a seedling cohort, where ingrowth drives stems from 1,000 to about 2,800 ha⁻¹ before any
self thinning, so Reineke fails in every trajectory, and the four QC ESI levels span only 2.5 m.

## Design, as proposed

Starting states: measured qc_c t1 stand lists (screened, cut FALSE), not synthetic seedlings, so the projection starts where
the benchmark supports the anchor. Selection, fixed before any run: stands stratified by QC ESI (four bins on the admitted range)
and by stand density (three bins of SDI at t1), with a fixed seeded draw of three stands per cell from fold B, so the 36 runs
match the PREREG31 cell count; species mix as observed. Arms: qc141 (QC_AFAC 0.111) and p38_fit (1.242), both new runs through
the PREREG31 driver (md5 467fb518) in a new grid mode that reads stand lists, which needs a reviewed driver change (a new mode
beside `grid` and `g0`, with a G0 identity gate that the existing modes are unchanged). 100 annual steps, five year reads.

Relations: the PREREG31 set, with two changes that must be argued before registration: Reineke evaluated only after the
trajectory reaches 0.5 of the QC frontier, since a measured stand list below the frontier cannot follow a self thinning line;
and site ordering across ESI bins tested on bin means rather than single trajectories, since real stands differ in more than
ESI. Non inferiority as PREREG31 (no new flags; worst margin not larger), with the PREREG26 realism tests reported.

## Open choices for Aaron

1. Whether the relation changes above are acceptable or the PREREG31 rules stay verbatim.
2. Whether the grid counts as the release gate for QC in 14.2 (reopening the close out if it passes) or only informs 14.3.
3. Driver change review: the new stand list mode touches the PREREG31 driver block, not the model files.

## Not decided here

Any gate value, provenance or stand draw seed; these are fixed only in the registered revision.
