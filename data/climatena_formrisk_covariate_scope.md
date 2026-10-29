# Scope: ClimateNA DD5/FFP launcher for covariate hardwood form/risk prediction (candidate d)

16 July 2026. Scopes the optional upgrade from the fixed observed-distribution split (Smith Table A.9 marginals, currently in `scripts/hw_formrisk_split.R`) to covariate-based form and risk prediction using Smith 2022 equations 1 to 4. This is candidate (d) in the record-split direction. Scope only, no build yet. Grounded in `data/smith_formrisk_prediction_appendixA.md` and `data/hardwood_form_risk_investigation.md`. No em dashes. FIA true coordinates stay on Cardinal; Claude tools cannot initiate the outbound climate fetch, so the deliverable is a turnkey launcher Aaron runs.

## Why upgrade, and the honest ceiling

The current split assigns every hardwood of a given species the same form and risk marginal from Table A.9, so two red maples of the same species get identical class weights regardless of size, competition, or site. Covariate prediction (Smith eq 1 to 4) makes the weights per tree and per plot: a high-BAL, spindly stem predicts more risk, a large open-grown stem predicts better form. That site and competition sensitivity is the entire value proposition.

The ceiling is set by Smith's own central negative result: hardwood form and risk predict weakly, fixed-effects AUC 0.63 to 0.66 across the four models (0.65, 0.66, 0.65, 0.63 for ideal form, R1, R2, R3 in the Chapter 1 body). So covariate prediction may not beat the observed-marginal split on accuracy; it buys responsiveness, not discrimination. Treat this as a sensitivity and realism upgrade, not an expected accuracy win, and sequence it AFTER the observed-marginal record-split is validated against Seven Islands.

## What each equation needs (from Appendix A)

The four hardwood models and their off-tree-list dependency:

- Eq 4, P(R3) = logit^-1( b40 + b41 log(HT/DBH) + b42 Tallest/HT + b43 BAL + b44 SPP ). Predictable from a tree list alone. log(HT/DBH), Tallest/HT (mean height of the 100 tallest trees per plot), and BAL are all derivable in place. NO external climate data.
- Eq 1, P(ideal form F1) = logit^-1( b0 + b1 HT + b2 DD5 + b3 SPP ). Needs DD5.
- Eq 2, P(R1) = logit^-1( b20 + b21 HT/DBH + b22 FFP + b23 SPP ). Needs FFP.
- Eq 3, P(R2) = logit^-1( b30 + b31 BAL + b32 FFP + b33 SPP ). Needs FFP.

So DD5 (growing degree-days above 5 C) and FFP (frost-free period) are the entire external dependency. Both are ClimateNA products (Wang 2015), keyed to plot location and a normal period. No site index and no other off-tree-list covariate appears in the hardwood set. Note the transcribed Eq 3 SE values for BAL and FFP are internally inconsistent with their p-values in the thesis table (likely a typesetting error); the point estimates are legible and usable, but flag Eq 3 for a coefficient re-check before production use.

## The class-system bridge to the engine

The engine's record-split works in discrete NHRI codes F1 to F8 and R1 to R4. Smith eq 1 predicts P(F1) (ideal, single straight stem, = STM); eq 2 to 4 predict P(R1), P(R2), P(R3) separately (R4 was not modeled for hardwoods). To feed the split, convert the eq outputs to the marginal vectors the splitter consumes: form marginal as P(F1) for the ideal cell and the observed Table A.9 conditional shares of F2 to F8 for the remainder (Smith models only the F1 vs F2-to-8 binary, so the non-ideal shape still comes from A.9); risk marginal as the normalized (P(R1), P(R2), P(R3)) with R4 folded into R3 or taken from the A.9 R4 share. The joint stays the outer product of form and risk marginals unless a correlated joint is modeled (see the independence caveat in the investigation md, red-team finding F4). This keeps `split_formrisk` unchanged in structure; only the per-tree marginal source changes from a static A.9 lookup to a predicted vector.

## Launcher design (turnkey, Aaron runs the fetch)

Four components, none of which initiate an outbound fetch from Claude tools:

1. `scripts/climatena/climatena_input_builder.R`. Reads a plot table (CFI: plot id, latitude, longitude, elevation) and writes the ClimateNA input CSV in the exact format ClimateNA expects (ID1, ID2, lat, long, el), degrees decimal and elevation in m, one row per plot, deduplicated to unique plot locations.
2. `scripts/climatena/RUN_CLIMATENA.txt`. A runbook: which ClimateNA build, the normal period (default Normal_1991_2020, or the period matching the inventory remeasurement), the two annual variables to request (DD5, FFP), and the expected output CSV. Aaron runs ClimateNA locally (desktop or CLI) against the input CSV. This is the sanctioned outbound step.
3. `scripts/climatena/climatena_join.R`. Reads the ClimateNA output, extracts DD5 and FFP per plot id, and joins them to the tree list at the plot level, with a coverage check (every modeled plot has DD5 and FFP) and a range sanity check.
4. `scripts/hw_formrisk_predict.R`. Carries the eq 1 to 4 coefficient tables from Appendix A (Tables A.1 and A.2), computes per-tree P(F1), P(R1), P(R2), P(R3) from the joined climate plus the in-place tree/competition terms, assembles the form and risk marginal vectors, and returns them in the shape `split_formrisk` consumes behind a toggle (for example `ops$use.formrisk.pred`, default off so the A.9 split stays the baseline).

## FIA versus CFI

CFI plot coordinates are known, so the ClimateNA join is straightforward and precise. For FIA the true coordinates are restricted and stay on Cardinal; DD5 and FFP vary slowly over space (both are smooth climate normals), so a join on the public fuzzed coordinates carries only small error at the roughly 1 km fuzzing scale, consistent with the `fia-coordinates` skill guidance that smooth covariates tolerate fuzzing. Recommendation: build and validate for CFI first, then add the FIA path using fuzzed coordinates for the climate join only, keeping true coordinates server-side and never in any deliverable. If a precise FIA join is ever needed, run the ClimateNA extract on Cardinal against the restricted coordinates and release only the joined DD5/FFP attributes, not the coordinates.

## Validation plan

Before trusting predicted marginals: compare covariate-predicted per-species mean marginals against the Table A.9 observed marginals as a calibration check (they should agree in aggregate; large divergence signals a coefficient or units error). Then run the record-split A/B with `ops$use.formrisk.pred` on versus the A.9 split, on hardwood BA, TOTVOL, VALUE, SAWVOL, gated vs cb_v12101. Expect little to no accuracy gain given AUC 0.63 to 0.66; the test is whether site and competition responsiveness improves behavior in specific strata (for example high-BAL stands predicting more risk and lower sawlog) without regressing the pooled metrics. Real value validation still needs the Seven Islands observed form/risk and measured sawlog set (NSF CAFS INTERN 1915078, via Weiskittel).

## Recommendation

Defer the build. Sequence: (1) gate the observed-marginal record-split (job 12390203, and candidate a ingrowth split if warranted); (2) source Seven Islands for real value validation; (3) only then build this ClimateNA covariate launcher, starting with CFI, as a responsiveness upgrade rather than an accuracy play. The launcher scope above is ready to execute when that point is reached. Estimated build: about a day for the CFI path (four small scripts plus the coefficient transcription already done in Appendix A), plus Aaron's one ClimateNA run.
