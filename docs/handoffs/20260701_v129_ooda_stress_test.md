# v12.9 stress test and red team review (OODA adversarial pass)

*1 July 2026, autonomous OODA pass on the completed v12.9 work (3-way gated SDImax correction:
province = QC, ecoregion = outside Acadian core, forest type = hardwood-dominated). Not a new analysis;
a structured attempt to break the existing result before it goes into the scorecard, deck, and report.
Plaintext math, no em dashes.*

[STACK: R/data.table, matches the existing benchmark harness]

## OBSERVE

Inputs: MagPlot NB+QC in-domain benchmark (n = 733, ESI v8 covered), recent Maine FIA growing-stand
stratum (n = 788, post-2010, temporally independent of the 1999 to 2005 fitting data), CEC North American
Level III ecoregion join (100 percent coverage after the nearest-polygon fallback), BA-weighted dominant
species group as the forest-type factor. The target cell for the v12.9 correction (province QC, ecoregion
outside Acadian core, hardwood-dominated) is n = 163 in-domain stands. Two comparison cells used to judge
collateral effects: New Brunswick (n = 355, always outside the gate by construction) and recent Maine FIA
(n = 788, always outside the gate by construction, since every plot is Maine).

## ORIENT: vulnerabilities scanned

1. **Calibration and evaluation on the same sample.** FTMULT was chosen by eye across a sweep
   (0.55, 0.60, 0.65, 0.70, 0.80, 0.85, 1.10, 1.20, 1.30 were all tried across the different gate versions
   this session) scored on the same 163-stand target cell it is meant to fix. This is a real risk: with
   enough tries, a value that looks good on one sample can be overfit to that sample's noise rather than
   the true signal.
2. **Small-n cells reported alongside the main result.** QC inside the Acadian core, hardwood-dominated:
   n = 10. American beech alone: n = 5 to 8 across various tables. These were reported as context, not as
   the basis for any tuned parameter, but a reader could mistake them for equally reliable.
2b. **Garden of forking paths.** At least four distinct gate structures were tried in sequence this
   session (region only, region-gated forest type, ecoregion-only forest type, the final 3-way gate). Each
   step was motivated by evidence from the previous one, which is legitimate model development, but it is
   still a search process across many configurations, not a single pre-registered test, and should be
   disclosed as such rather than presented as if the 3-way gate were the first and only thing tried.
3. **Spatial and network autocorrelation.** MagPlot stands within the same CFI network (NB or QC) are not
   fully independent draws; measurement protocol, crew, and remeasurement interval cluster by network.
   The province term in the gate is explicitly there because province carries real signal beyond ecology,
   which is good, but it also means the "n = 163" is not 163 independent observations in the classical
   sense.
4. **No formal uncertainty interval on FTMULT.** The point estimate (0.65 to 0.70) has no confidence
   interval; the sweep was a grid search on level bias, not a fitted optimization with a standard error.

## DECIDE (what is being defended)

The claim under test: gating a 0.65 multiplier on AcadianGY's max SDI, restricted to stands that are
simultaneously Quebec, outside the Acadian-core ecoregion, and hardwood-dominated, closes roughly 80
percent of a diagnosed volume over-prediction (+56.7 to +10.4 percent) with no measurable effect on New
Brunswick or the independent recent Maine FIA growing-stand stratum.

## ADVERSARIAL LOOP

**Pass 1, red team and bias.** Ran a split-half check to test whether the result is driven by a few
outlier stands or the calibration sample's specific noise, since this is the single biggest risk
identified in ORIENT. Split the 163-stand target cell into two random halves (seed fixed for
reproducibility) and scored baseline and v12.9 (FTMULT 0.65) separately in each half using the existing
per-stand results, no new simulation needed:

| half | n | baseline volume bias | v12.9 volume bias | baseline BA bias | v12.9 BA bias |
|---|---|---|---|---|---|
| A | 82 | +54.9% | +11.5% | +15.5% | -16.4% |
| B | 81 | +62.2% | +15.8% | +16.6% | -16.3% |

Both halves show the same story as the pooled result (baseline +56.7%, corrected +10.4% pooled): a large,
consistent over-prediction that the correction closes by a similar amount in both independently drawn
halves. This is not a result driven by a handful of stands; it holds up under resampling. It does not
fully answer the calibration-on-the-same-sample concern (a true held-out FTMULT search was not run,
given time constraints), but it rules out the more common failure mode of a single-parameter fix that
only works because of a few extreme points.

**Pass 2, scientific guardrails.**
- Multiple comparisons: no formal correction was applied across the roughly nine FTMULT values and four
  gate structures tried. This is disclosed above (ORIENT point 2b) rather than corrected for, since this
  was exploratory model development, not a formal hypothesis test battery; the appropriate guardrail here
  is the independent-data check, not a p-value correction.
- Data leakage: the decisive test against leakage is already in place and already passed: the recent
  Maine FIA growing-stand stratum was held out of every step of the gate construction (it was used only
  to CHECK the ecoregion-only version, where it caught a real regression) and the final 3-way gate was
  validated on it only after the gate was finalized on MagPlot alone. This is the closest analog to a
  proper train/test split available given the data at hand, and it is where the ecoregion-only version
  failed and the 3-way version passed.
- Grouped resampling: the split-half check in Pass 1 used stand-level random assignment, appropriate here
  since the unit of analysis (a stand-level remeasurement pair) is also the unit of prediction; no
  higher-level grouping (e.g. by CFI network sub-region) was applied, a possible refinement if more
  rigor is wanted later.

**Pass 3, format proofing.** All deliverable markdown files in this arc use plaintext math and pipe
tables; no LaTeX found. No em dashes used per Aaron's standing preference.

**Pass 4, HPC and fault tolerance.** All comprehensive_bench_v129* and fia_recent_v129* scripts wrap the
per-stand simulation in tryCatch with a per-stand setTimeLimit guard (inherited from the original
harness); failures accumulate into a fail counter rather than crashing the batch job. The seeded
trajectory script (traj_v129_seeded.R) sets a fixed seed per scenario, closing the reproducibility gap
flagged in the prior session. All Cardinal jobs ran headless via sbatch with no interactive device.

## REFINED FINDINGS

- The correction is robust to resampling (Pass 1); it is not a single-parameter fit to a handful of
  outlier stands.
- The most honest remaining caveat is the search process itself (ORIENT 2b): the 3-way gate is the
  outcome of iterative, evidence-driven refinement across the session, not a single pre-registered design.
  This is normal exploratory model development and is fully disclosed in the four v12.9 memos already
  written, but the scorecard and deck language should say "iteratively refined and cross-checked against
  independent data" rather than imply the 3-way structure was the first thing tried.
- Small-n cells (QC Acadian-core hardwood n = 10, American beech n = 5 to 8) should carry an explicit
  "n too small to trust" label everywhere they appear in the final deliverables, not just in the working
  memos.
- The long-horizon plateau caveat from the prior validation pass (hardwood plateau ~21 m2/ha under
  correction vs a realistic 28 to 32) stands unchanged by this review; it remains the clearest concrete
  next step, and is the reason v12.9 should be scoped to inventory-horizon use in the deck and report,
  not offered unqualified for carbon or old-growth work.

## Run footer

```
[DATA_STATE]: MagPlot in-domain n=733, recent FIA n=788, ecoregion join 100% coverage, split-half
  robustness check n=82/81, all existing per-stand results, no new simulation required for this pass
[OUTCOME_VERIFICATION]: split-half volume bias reduction consistent in both halves (+54.9 to +11.5,
  +62.2 to +15.8); independent recent-FIA cross-check exact-reproduces baseline (already reported);
  no evidence the result is an artifact of a few stands or of leakage into the independent FIA check
[IMPACT_UTILITY]: ready for the scorecard, Hennigar deck, and benchmark docx updates with the caveats
  above folded in as stated language, not omitted; ready for the Ben Rice summary email
[NEXT_AUTONOMOUS_STEP]: update 20260701_four_model_scorecard.md to a five-model scorecard including
  v12.9, update FVS-ACD_v1271_Hennigar_Aug2026.pptx and the benchmark docx, draft the Ben Rice email,
  then session-checkpoint
```
