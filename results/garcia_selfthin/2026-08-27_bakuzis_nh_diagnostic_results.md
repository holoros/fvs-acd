# N/N(H) diagnostic added to bakuzis_check.R, and what it found at CTRN

August 27, 2026. Step two of the scoping document's three-step recommendation
(`2026-08-26_garcia_engine_integration_scoping_DRAFT.md`, section 5): add the Garcia
self-thinning relation to `bakuzis_check.R` as a diagnostic, evaluating N/N(H) along every
trajectory the battery already produces. Implemented, committed, and run against the four
committed CTRN, memat, and nb trajectory files.

## What was added

A new section 4b in `results/bakuzis/scripts/bakuzis_check.R`, immediately after the Reineke
slope test, computing N(H) = 10^4 (beta H)^(-2 gamma / alpha) at every age using the pooled
Garcia (2009) coefficients from `garcia_nlme_coef_restricted3_2026-08-26.csv` (alpha 3.22206,
beta 0.068077, gamma 5.68834, read from file rather than hardcoded, with a labelled fallback if
the file is unreachable from the trajectory's location). It fires on every origin and site
combination regardless of whether the Reineke test above it could run, which matters because
Reineke reports "n/a, not in a self-thinning regime" at all four CTRN sites, meaning CTRN
previously had no working self-thinning test in the battery at all. A ratio over 1.0 is flagged,
a sustained ratio over 0.8 is noted without flagging. This is diagnostic only, per the scoping
doc's own framing: it reports and flags, it does not constrain any projection, and a flag here
does not by itself argue for building the sdm_mfrac cap described in the scoping doc's option C.

## What it found

Run against the two CTRN trajectory files already committed under `results/bakuzis/data/`
(`ctrn_h1default_traj.csv`, the current production default with the h1_v132_mortgate lever, and
`ctrn_v132baseline_traj.csv`, the v13.2 baseline without it), plus memat and nb for comparison.

CTRN's two lower site classes, 14.3 and 15.8, stay under the ceiling in both configurations,
ranging 0.13 to 0.80. CTRN's two higher site classes exceed it, and do so almost identically
under both lever configurations: site 17.2 ranges 0.107 to 1.332 under h1_v132_mortgate and
0.107 to 1.335 under the v132 baseline, crossing 1.0 at 20 of 100 simulated ages and staying
above 0.8 at 31; site 18.1 ranges 0.090 to 1.201 under h1_v132_mortgate and 0.090 to 1.220 under
baseline, crossing 1.0 at 10 ages and staying above 0.8 at 16 to 17. The near-identity between
lever configurations (1.332 vs 1.335, 1.201 vs 1.220) means this is not something the mortgate
lever introduced or fixed, it is a property of CTRN's two highest site-index trajectories present
under both. memat (four site classes, 12.9 to 18.2) and nb (four site classes, 17.4 to 19.4)
stay under 0.80 at every age tested, so this is not a general engine property either, it is
specific to CTRN at high site index.

This is a different case from the one the scoping document examined. That document's own N/N(H)
table, built from the pass 32 CTRN production trajectory at a single site class (14.3), ran 0.36
to 0.42 throughout and never approached 1, which is the basis for its conclusion that a hard
ceiling would be measurably inert there. The new finding, at the two higher site classes this
diagnostic newly covers, is a real crossing rather than a comfortable margin, and it was invisible
to the battery before this addition because Reineke could not run at CTRN at all.

## What this does and does not mean for step three

It does not, by itself, revive the case for the engine-side constraint (option C,
`ops$use.sdimort` behind `ops$use.garcia.selfthin`). The scoping document's falsification
criteria and acceptance criteria were built around the pass 32 crash-depth pathology, and nothing
here speaks to whether CTRN's high-site trajectories exhibit that same volume crash or whether
Eichhorn or the other Bakuzis relations flag anything else at those two site classes; a quick
check on the same files shows Eichhorn passing cleanly (mean CV 9.1 percent, site-independent),
so the trajectories are not obviously pathological in the way pass 32 was. It does mean the
diagnostic is doing its job, since it surfaced a real, previously invisible boundary crossing at
exactly the two site classes densest at a given height, which is where a self-thinning ceiling
should be expected to bind first if it binds anywhere.

## Files

`results/bakuzis/scripts/bakuzis_check.R` (patched, prior version backed up locally as
`bakuzis_check_PREV_20260827.R`, gitignored per repo convention). This note. No trajectory data
or coefficient file was changed.

## Narrow follow-up, 27 August 2026: does CTRN's high-site ceiling crossing share the crash pathology?

Aaron asked whether to proceed straight to the full step-three benchmark or narrow first. Narrowed
first. The scoping document's own crash-depth and volume-to-basal-area diagnostics
(`2026-08-26_garcia_engine_integration_scoping_DRAFT.md`, "the diagnostic that distinguishes
prevention from masking") were run against all four CTRN site classes in both trajectory files, not
only the two that cross the Garcia ceiling.

**Table.** Crash depth (min standing volume over ages 40-70, as a fraction of the trajectory's own
age-40 volume) by CTRN site class and configuration.

| Site | h1_v132_mortgate crash depth | v132 baseline crash depth | Max N/N(H), ages 0-100 |
|---|---:|---:|---:|
| 14.3 | 0.748 | 0.787 | 0.771 (never breaches) |
| 15.8 | 0.777 | 0.787 | 0.802 (never breaches) |
| 17.2 | 0.735 | 0.746 | 1.332 (breaches, 20/100 ages) |
| 18.1 | 0.919 | 0.925 | 1.201 (breaches, 10/100 ages) |

Site 17.2 does show the deepest crash of the four and the worst ceiling breach together, and its
volume-to-basal-area ratio through the crash window only rises (0 to 8.3 percent above the age-40
value under h1_v132_mortgate, 0 to 7.6 percent under baseline), never falls, which is not the
signature the scoping document names for masking (a constraint that retains small stems holds basal
area while volume per unit basal area falls). So site 17.2's crash looks like a real crash rather than
an artifact, and it happens to coincide with the worst ceiling breach.

But site 14.3, the scoping document's own reference site, crashes almost as deep, 0.748, while never
approaching the Garcia ceiling at all, max N/N(H) 0.771 across the full 100-year horizon. Site 15.8 is
similar, crash depth 0.777, max N/N(H) 0.802. So crash depth does not track ceiling proximity across
the four CTRN sites: the two sites furthest from the ceiling crash nearly as deep as the one site
closest to it, and site 18.1, which does breach the ceiling, has the shallowest crash of all four,
0.919, barely a dip. A single coincidence (site 17.2) is not a pattern against three site classes that
contradict it.

One number does not reconcile and is flagged rather than smoothed over. The scoping document's own
reported crash depth at CTRN, "178.2 against 223.8, a trough at 0.796," matches this data's site 14.3
age-40 volume of 223.8 exactly but not its computed trough, 167.3 rather than 178.2, giving 0.748
rather than 0.796. The window definition, exact trajectory file, or config used for the original
number was not re-derived here and the discrepancy should be resolved before either figure is quoted
again, though it does not change this section's conclusion either way since 0.748 is if anything a
slightly deeper crash than the document's own 0.796.

**Conclusion.** This does not support proceeding to step three. The one candidate coincidence, site
17.2 pairing the deepest crash with the worst ceiling breach, does not generalize across CTRN's other
three site classes, and the crash is present, to a comparable or greater depth, at sites that never
come near the Garcia ceiling. This is consistent with, and adds a second line of evidence to, the
scoping document's own falsification result that switching `ops$use.sdimort` off entirely does not
repair the crash: if the mechanism the Garcia ceiling would constrain were driving the crash, crash
depth should track ceiling proximity, and here it does not. Recommendation: park step three on the
current evidence. The Garcia relation's contribution to this engine remains diagnostic (the N/N(H)
section above, now standing infrastructure in `bakuzis_check.R`), not constraining, and nothing found
in this narrow follow-up changes that reading. Revisit only if a future crash investigation finds a
mechanism this diagnostic would actually gate.
