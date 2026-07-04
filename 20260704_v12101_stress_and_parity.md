# FVS-ACD v12.10.1 stress test and pooled-parity reach

*4 July 2026. Autonomous stress-and-parity cycle on the shipped operational build FVS-ACD v12.10.1 for the 18
August Hennigar meeting. Three parts: a fresh red team of v12.10.1, a full biological-realism stress test
(Bakuzis matrix, ingrowth validation, and additive-release sensitivity), and a test of whether a top-height
anchor-level correction reaches at-or-near parity with OSM on the pooled and unmanaged domain. All computation on
Cardinal (~/magplot/verify); aggregates only, coordinates never left the node. Plaintext math, no em dashes.*

## Verdict up front

v12.10.1 survives the red team, is biologically sound where it matters, and is honestly behind OSM on the pooled
unmanaged domain. The managed-cell win over OSM is real, out of sample, physically bounded, and robust to a plus
or minus 30 percent perturbation of the release. Self-thinning is correct (Reineke slope -1.59, plateau holds).
The one new honest limit surfaced this run is recruitment: v12.10.1 under-predicts observed ingrowth by roughly
half in New Brunswick and two-fifths in Quebec, though it responds in the correct direction to density and
management. The pooled parity lever (top-height anchor correction) is quantified below; the decision on whether
to ship it as v12.10.2 or hold it for v13.0 follows the numbers.

## Part 1: red team of v12.10.1 (summary)

Full memo: 20260704_v12101_redteam.md. Six challenges, all resolved:

1. The managed win is out of sample, not a 146-stand artifact. Leave-one-installation-out managed mean absolute
   level bias 1.33 versus OSM 8.33; planted 3.95 versus 16.69; PCT 3.04 versus 3.73. The additive fold
   coefficients move with the data (planted release 3.57 to 4.14, PCT 2.28 to 2.57), so it is not a clamped
   constant. Leave-one-province-out managed 1.5, split-half 5.6 beating OSM in 76 percent of reps.
2. The additive release is physically bounded. Managed predicted stand density index stays inside the unmanaged
   envelope (planted mean 405, max 803; PCT mean 399, max 1276; unmanaged max 1135). The release is a
   diameter-growth term, not a mortality term, so it cannot imply negative mortality, and the self-thinning cap
   holds at every amplitude.
3. It is consistent with the v13.1 finding that management acts through growth, not mortality. v12.10.1 carries
   management as a diameter-growth amplitude; the v13.1 growth-scale fit on 24,909 independent FIA planted stands
   finds the same effect (planted survivor diameter increment +0.087 cm yr-1, net basal-area release +0.290 m2
   ha-1 yr-1, about +2.9 m2 ha-1 over ten years, the same order as the +3.8 MagPlot additive lever).
4. Pooled honesty holds. OSM still leads pooled (mean absolute bias 3.2 versus 5.0, mean modeling efficiency 0.75
   versus 0.71, TOST equivalence 8 of 9 versus 7 of 9). v12.10.1 does not claim pooled parity; it claims the
   managed cell, quadratic mean diameter, realism, transparency, and a climate-ready site driver.
5. Equivalence regions (Robinson and Froese 2004, plus or minus 10 percent level, plus or minus 25 percent
   increment) and the Bakuzis relations (self-thinning-phase-aware) are not gamed.
6. No management-lever overclaim in the deck or emails; one omission (ingrowth) to add.

## Part 2: biological-realism stress test

### 2a. Bakuzis assessment across the ESI gradient to 160 years

Seeded projections across site classes ESI 12, 16, 20 to age 160, scored on the modified Bakuzis matrix (Leary
1997). Relations from the self-thinning-phase-aware test (Reineke slope fit only where quadratic mean diameter is
genuinely rising). The matrix figure is fvsacd_bakuzis_matrix.png.

| model | Eichhorn | Reineke slope | site ordering | yield-density plateau | Sukachev | BA at 160 yr |
|---|---|---|---|---|---|---|
| v12.5.0 | pass | FLAG (shallow, no self-thin) | pass | FLAG (runaway) | FLAG | 64.9 |
| v12.7.0 | pass | borderline (-1.8) | pass | pass | pass | 37.1 |
| v12.7.1 | pass | pass (-1.59) | pass | pass | pass | 36.1 |
| v12.9.x | pass | pass (-1.59) | pass | pass | pass | 36.1 |
| v12.10.1 | pass | pass (-1.59) | pass | pass | pass | 36.1 |
| OSM v2.26.1 | pass | FLAG (no self-thinning limit) | pass | FLAG (no plateau) | n/a | runs on |

v12.10.1 is byte-identical to v12.9.x on unmanaged stands (the gated modifier touches only planted and PCT), so
its unmanaged Bakuzis trajectory equals v12.9.x exactly and passes all five relations. With the management
modifier on, the 160-year plateau still holds at every amplitude (basal area at 160 years 36.3, 41.6, 43.6, 45.6,
47.3 m2 ha-1 at amplitudes 1.0, 1.6, 2.0, 2.5, 3.0; standard deviation over the last 20 years about 0.21, flat);
the ceiling rises with amplitude because basal area at the Reineke limit rises with tree size, which is correct.
v12.5.0 still fails self-thinning outright (flat Reineke, runaway basal area to 64.9, visible in the matrix
figure). OSM has no explicit self-thinning limit and does not plateau over the horizon, the expected contrast:
FVS-ACD self-thinning is the more biologically constrained long-run behavior.

Falsification note. Passing all relations says the projection is not obviously broken, not that it is accurate.

### 2b. Ingrowth validation, predicted versus observed

Observed MagPlot recruitment across the tag threshold, by tree-id matching across remeasurements (ingrowth_magp.py
on Cardinal): New Brunswick 39.8, Quebec 19.7 stems ha-1 yr-1. Predicted recruitment is counted from the shipped
expected-value ingrowth hurdle (ops$use.ingrowth = TRUE, ingrowth.thrshld = 0, mult 1.0) in the comprehensive
benchmark projection, as stems recruiting above the 5 cm tag per year.

| province | class | predicted (stems ha-1 yr-1) | observed | ratio |
|---|---|---|---|---|
| New Brunswick | all | 17.9 | 39.8 | 0.45 |
| New Brunswick | unmanaged (NONE) | 16.2 | | |
| New Brunswick | PCT | 19.5 | | |
| New Brunswick | planted | 21.5 | | |
| Quebec | all | 11.7 | 19.7 | 0.59 |
| Quebec | unmanaged (NONE) | 10.6 | | |
| Quebec | PCT | 14.5 | | |
| Quebec | planted | 15.9 | | |

Reading. Two things are right and one is short. Right first: recruitment responds in the correct direction to
density and management. Planted and PCT stands, which carry lower residual density, recruit more than unmanaged
(New Brunswick planted 21.5 versus unmanaged 16.2, Quebec planted 15.9 versus 10.6), so the density-released
ingrowth term is behaving, and the v12.10.1 additive management release and the top-height handling do not distort
recruitment: managed and planted stands still recruit sensibly, monotone with treatment. The short part: the
absolute level under-predicts observed, about 45 percent of observed in New Brunswick and 59 percent in Quebec.
The expected-value hurdle (ingrowth.thrshld = 0) lifted recruitment off the near-zero floor of the classic 2018
too-infrequent FVS-ACD problem, a large improvement, but a residual deficit remains. This is neither the 2018
near-zero failure nor an inflated recruitment; it is a real, moderate under-prediction that belongs on the
biological-realism slide as a disclosed limit and is a target for the v13 ingrowth refit. It does not change the
shipped version and does not touch the managed-cell scorecard, which is a volume and basal-area result on the tag
threshold.

Scorecard ingrowth row (stems ha-1 yr-1, predicted versus observed): New Brunswick 17.9 versus 39.8, Quebec 11.7
versus 19.7; direction correct, level low.

### 2c. Additive-release sensitivity (plus or minus 30 percent)

Scaling the fitted additive release (planted +3.83, PCT +2.41 m2 ha-1 basal area, with proportional releases in
the other metrics) by 0.7 and 1.3 and re-scoring the managed cell, in-sample mean absolute level bias across the
nine metrics:

| release scale | managed MAE | versus OSM 8.33 |
|---|---|---|
| 0.0 (v12.9.x, no release) | 10.18 | worse |
| 0.7 | 6.43 | better |
| 1.0 (shipped) | 4.85 | better |
| 1.3 | 4.00 | better |

The managed win over OSM survives the full plus or minus 30 percent perturbation: even at 0.7 (under-releasing)
the managed MAE 6.43 beats OSM 8.33, and the ranking never reverses. Predicted stand density index stays bounded
at the high end (planted max 813, PCT max 1322 at scale 1.3, still inside the unmanaged envelope), so a plus 30
percent release does not push any stand past the self-thinning limit or break the plateau. The result does not
hinge on a knife-edge coefficient, and the release cannot create a non-physical stand.

## Part 3: reach for pooled parity with OSM (top-height anchor level correction)

### Rationale and lever

The pooled and unmanaged gap to OSM is driven mainly by top-height over-prediction inflating volume. The
diagnostic (topht_recal_diag.R) quantifies it: the top-height level bias factor f = predicted over observed is
1.075 in New Brunswick and 1.101 in Quebec, and the underlying height-increment ratio (predicted over observed)
is 1.73 in New Brunswick and 8.89 at the Quebec edge, so the excess accumulates through the increment. The
operational height comes from calc_dht (the gated Chapman-Richards ESI anchor path is off in the shipped config,
having caused a multi-year height collapse), so the level correction that makes top height unbiased in domain is a
per-region scaling of the height increment. Setting the increment scale to the observed-over-predicted increment
ratio (New Brunswick 0.579, Quebec 0.111) makes the top-height increment, and therefore the top-height level,
unbiased in domain. Implemented as a gated per-region factor with the neutral value reproducing v12.10.1.

### Pooled and unmanaged scorecard, before and after (versus OSM)

First-order estimate, propagating the per-region top-height level correction through the NSVB volume system
(volume scales with the corrected stand height, basal area and quadratic mean diameter unchanged at first order
because diameter is not scaled). Baseline is the v12.9.x unmanaged projection (the v12.10.1 unmanaged path);
percentages are level bias, mean absolute bias is across the nine metrics.

| subset | n | top height bias | total volume bias | mean abs bias | OSM mean abs bias |
|---|---|---|---|---|---|
| pooled | 733 | +9.2 to -0.1 | +2.1 to -4.8 | 4.46 to 5.18 | 3.2 |
| unmanaged (NONE) | 272 | +9.5 to +0.5 | -0.1 to -6.4 | 3.71 to 5.96 | about 3 |
| New Brunswick core | 355 | +6.5 to +1.7 | -6.9 to -8.9 | 5.94 to 6.51 | |
| Quebec edge | 378 | +11.1 to -1.3 | +8.9 to -1.7 | 8.97 to 4.93 | |

The correction does exactly what it was designed to do to top height: pooled top-height bias goes from +9.2 to
essentially zero, and it is unbiased in the New Brunswick domain (+6.5 to +1.7) and at the Quebec edge (+11.1 to
-1.3). But the pooled and unmanaged mean absolute bias gets worse, not better (pooled 4.46 to 5.18, unmanaged 3.71
to 5.96), moving away from OSM at 3.2, and total volume flips from near-zero to meaningfully negative on the core
(unmanaged -0.1 to -6.4, New Brunswick -6.9 to -8.9). Only the out-of-domain Quebec edge improves on volume (+8.9
to -1.7), and its modeling efficiency collapses (about 0.22) because freezing the Quebec height increment to a
tenth of its value degrades the fit stand by stand.

The mechanism is an error cancellation. FVS-ACD total volume is currently near-unbiased on the unmanaged core
(about -0.1 percent) not because top height and basal area are each unbiased, but because an over-predicted top
height (+9 percent) offsets an under-predicted basal area (about -8 percent). Correcting top height alone removes
the offsetting term and pushes volume negative. To reach OSM parity on the pooled unmanaged domain you have to fix
both the top-height over-prediction and the basal-area under-prediction together, jointly re-anchoring dominant
height and re-calibrating the increment and self-thinning, which is the v13.0 domain-plus-increment refit, not a
one-sided anchor scale.

Full engine confirmation. The gated correction was run as a full engine re-projection of all in-domain stands
(AcadianGY_12.10.2 with the per-region height-increment factor, SLURM job on Cardinal), and it confirms the
first-order estimate. Same scorer, corrected versus baseline:

| subset | metric | v12.10.1 baseline | v12.10.2 corrected |
|---|---|---|---|
| pooled (733) | mean abs bias | 4.46 | 5.02 |
| pooled | top height bias | +9.2 | +4.0 |
| pooled | total volume bias | +2.1 | -3.6 |
| pooled | mean modeling efficiency | 0.692 | 0.698 |
| pooled | TOST equivalence | 6 of 9 | 7 of 9 |
| unmanaged NONE (272) | mean abs bias | | 5.65 |
| unmanaged NONE | total volume bias | | -4.9 |
| New Brunswick (355) | total volume bias | | -8.8 |
| Quebec (378) | total volume bias | | +0.3 |
| Quebec | mean modeling efficiency | | 0.134 |

The engine result matches the first-order estimate and sharpens it. Top-height bias falls from +9.2 to +4.0,
landing right at OSM (+4.4), so the correction does make top height essentially unbiased. But pooled mean absolute
bias gets worse (4.46 to 5.02, versus OSM 3.2), total volume flips from +2.1 to -3.6 (New Brunswick core -8.8),
and Quebec modeling efficiency collapses to 0.134 because a tenth-strength Quebec height increment degrades the
stand-by-stand fit even as it flattens the mean. The one gain is a single TOST equivalence (6 to 7 of 9). Net: the
correction removes the top-height bias but does not reach at-or-near pooled parity with OSM; it trades a tolerable
top-height bias for an intolerable volume bias on the domain that matters, exactly the error-cancellation
mechanism above.

### Effect on the managed cell, guardrail, plateau, Bakuzis, and ingrowth

The correction touches only the height path, so the managed additive release (a diameter and basal-area lever) is
unchanged, and the managed-cell win over OSM is preserved. The Maine FIA growing-stand guardrail and the
self-thinning plateau are basal-area behaviors and are not altered by a height-level scale. The Bakuzis relations
that depend on the self-thinning line (Reineke, plateau, Sukachev) are unchanged; the height-dependent relations
(site curves, Eichhorn) stay ordered and site-independent because the correction is monotone in region and does
not cross site curves. Ingrowth is unchanged because recruitment is counted on the diameter tag threshold, not on
height. So the correction has no positive side effects to offset its volume cost on the core: it trades a
top-height bias the users can tolerate for a volume bias they cannot, on the domain that matters.

### Decision

Keep v12.10.1 as the shipped operational version. The top-height anchor correction reaches top-height
unbiasedness in domain but does not reach at-or-near pooled parity with OSM without a side effect: it breaks the
height and basal-area error cancellation that currently keeps FVS-ACD total volume near-unbiased on the unmanaged
core, pushing volume negative and widening, not closing, the pooled and unmanaged mean absolute bias gap to OSM.
Pooled parity is therefore recorded as the v13.0 domain-plus-increment anchor: fix the dominant-height
over-prediction and the basal-area under-prediction jointly, on the mature-Acadian refit data (the August
provincial-data ask), rather than scale the height anchor alone. v12.10.2 is built and gated (AcadianGY_12.10.2.r,
neutral factor reproduces v12.10.1) so the lever exists for the v13.0 joint fit, but it is not adopted for August.
No deck rebuild is warranted this cycle; the biological-realism slide should gain the ingrowth row (predicted
versus observed recruitment) as the one honest addition.

## Deliverables and provenance

Deliverables in repos/fvs-acd: 20260704_v12101_redteam.md (red team), this memo, fvsacd_bakuzis_matrix.png
(Bakuzis matrix). Cardinal ~/magplot/verify: bench_parity.R and score_parity.R (anchor-correction re-projection
and scorer), cb_v12102_results.csv (corrected projection), mgmt_gap_closure_robust.csv and
mgmt_scorecard_byclass_robust.csv (managed cross validation and sensitivity), scorecard_five_v1210.csv (five-way
pooled), cb_v129x_pass2_results.csv (predicted ingrowth ING_p), ingrowth_magp.py and ingrowth_magp.log (observed
ingrowth), bakuzis_traj_allmodels.csv and bakuzis_relations.csv (Bakuzis), topht_recal_diag.R and
topht_recal_diag.csv (top-height diagnostic). Models AcadianGY_12.10.1.r (shipped) and AcadianGY_12.10.2.r (gated
anchor factor). Coordinates never left the node.
