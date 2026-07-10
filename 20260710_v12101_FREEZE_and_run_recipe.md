# FVS-ACD v12.10.1: freeze note and operational run recipe

*10 July 2026. Phase 1 of the v12.10.1 freeze and v13 migration plan. This pins the frozen August operational baseline, the exact recipe that reproduces its scorecard, and the reconciliation of the file-identity question raised in Phase 0. No equation or coefficient was changed; the only edit to the R file is a comment-only frozen header. No em dashes.*

## What is frozen

The operational FVS-ACD version for the 18 August 2026 Acadian Growth and Yield meeting is AcadianGY 12.10.1, AcadianVersionTag "AcadianV12.10.1". The canonical R source is now committed to the repo:

repos/fvs-acd/scripts/AcadianGY_12.10.1.r

pulled from OSC Cardinal ~/_scripts/AcadianGY_12.10.1.r on 10 July 2026, with a comment-only frozen-baseline header prepended (md5 of the headered file 027ad5e5532b801718f8ad0b22bada9d; the body below the header is byte-for-byte the Cardinal source). This is the file Ben Rice maintains and that goes into FVS.

Model content: the v12.9.x base (FIA NSVB volume and biomass, coupled two-segment relative-density mortality with density-released ingrowth, composition and ecoregion aware brms SDImax, ESI-consistent dominant-height anchor recalibration) plus the Chapter-11 direct-effect management modifiers, gated by ops$use.mgmt.mod with default OFF, so gate-off behavior is the v12.9.x growth and yield. The management modifiers are the robust additive direct-effect release that replaced the clamped 12.10.0 form: planted a sustained Type 2 diameter-growth release (mgmt.planted.mult 2.0), PCT a decaying Type 1 release (1 + a exp(-b tst), a 1.0, b 0.03 per year), fit as a 10 percent trimmed mean of per-stand observed minus predicted-untreated increment (planted +3.8, PCT +2.4 m2/ha basal area). Mortality is deliberately not given a multiplicative modifier; management as a hierarchical predictor is the v13.2 item.

## Operational run recipe (reproduces the base scorecard)

Run through bench_parity.R on Cardinal in ~/magplot/verify with:

```
export MODEL_FILE=~/_scripts/AcadianGY_12.10.1.r
export CONFIG_TAG=cb_v12101
export NB_AFAC=0.579 QC_AFAC=0.111
# bench_parity defaults (unchanged): ONSET 0.30, BREAK 0.62, BG 0.020, BS 0.80,
# IRC 0.58, IRK 8, SDMAX 1.0, USE_BRMS TRUE, USE_ANCHOR TRUE,
# NB_BREAK 0.70, QC_BREAK 0.62
module load gcc/12.3.0 R/4.4.0
Rscript bench_parity.R
```

Ops set inside bench_parity (the operational config): use.ingrowth TRUE (min DBH 5.0), use.sdimort TRUE with the two-segment onset/break/beta, use.brms.sdimax TRUE with the per-stand map, use.esi.anchor.recal TRUE with region esi.anchor.coef (NB c(0.885, 0.01027), QC c(0.441, 0.03783)), region self-thinning break and ingrowth multiplier, per-province dominant-height afac (NB 0.579, QC 0.111). Management modifiers are gated OFF in the base scorecard; the managed benchmark scores them separately (mgmt_scorecard_byclass_robust.csv).

The base scorecard from this exact file is cb_v12101_results.csv (adopted on Cardinal 10 July 2026 from the verified cb_1210chk run: 733 stands, 0 failures, so the file parses and runs cleanly).

## Reconciliation of the Phase 0 file-identity question

Phase 0 asked whether the standalone 12.10.1.r reproduces the published baseline cb_v12102. Answer: cb_v12102 was generated from AcadianGY_12.9.2.r (the immediate predecessor), not from 12.10.1.r. The two are close but NOT byte-identical in output, despite the 12.10.1.r header claim of gate-off parity with 12.9.x. On 705 matched unique stands the mean absolute stand differences are small (basal area 0.30, top height 0.04, total volume 1.9 m2/ha or m3/ha), with a handful of larger outliers (max total volume 72 m3/ha). Pooled level bias:

| model (source) | basal area | top height | total volume |
|---|---|---|---|
| v12.10.1 (12.10.1.r, cb_v12101) | -10.07% | +2.97% | -3.96% |
| v12.9.2 (cb_v12102) | -9.31% | +2.79% | -3.06% |
| difference | -0.77 | +0.19 | -0.91 |

The difference is under one percentage point on every metric and the offsetting signature (basal area under, top height over, canceling in volume) is unchanged, so the August scorecard story is intact. But the honest record is that the published cb_v12102 was a 12.9.2 approximation. The corrected canonical baseline is cb_v12101_results.csv, run from the actual frozen 12.10.1.r.

Implication for the v13 migration: the v13.0 gate should compare cb_v130 against cb_v12101 (the true v12.10.1 base), not cb_v12102. Update scripts/v130_score_gate.R accordingly in Phase 2 (swap the baseline filename), and note that the in-domain headline the deck and report use (basal area -9.2, top height +4.16, total volume -1.63) comes from the operational-domain recompute scorecard_domain_v12101.csv, which is the in-domain masked subset and remains the correct figure to cite.

## Status and next step

Frozen: scripts/AcadianGY_12.10.1.r (headered), cb_v12101_results.csv on Cardinal adopted as the canonical base scorecard. Not yet committed to the holoros GitHub remote; run github-manager to commit and tag "v12.10.1-frozen-aug2026" when ready, or it stays local in the workspace. Next: Phase 2, redirect the v13.0 height re-anchor to the esi.anchor.coef hook and gate cb_v130 against cb_v12101.

## Provenance

AcadianGY_12.10.1.r md5 027ad5e5532b801718f8ad0b22bada9d (headered), Cardinal source ~/_scripts/AcadianGY_12.10.1.r. Comparison files: cb_1210chk_results.csv (this file, gate-off) and cb_v12102_results.csv (12.9.2.r), both from bench_parity.R with NB_AFAC 0.579 QC_AFAC 0.111. Management engine and lineage documented in the 12.10.1.r header changelog. FIA true coordinates never left Cardinal.
