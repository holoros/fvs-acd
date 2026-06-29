# Acadian growth model benchmarking: v12.5.0 to v12.6.1

**29 June 2026. DRAFT benchmarking report, structured after Ben Rice's AcdBenchCompare. Two parts:
growth-model bias across FVS-ACD versions, and long-term projection reasonableness (Bakuzis).
Plaintext math, no em dashes.**

## Objectives

Following the AcdBenchCompare framework, this report evaluates the evolution of FVS-ACD across the
12.6.x development cycle on two axes: (1) the bias of stand-level predictions against observed
remeasurement growth, contrasted across model versions; and (2) the biological reasonableness of
long-term projections across a site gradient. The aim is to document what each 12.6.x change does to
prediction bias and to long-term behavior, so the team can decide what enters the production variant.

Sign convention note: AcdBenchCompare reports bias as observed minus projected. This report reports
percent bias as predicted over observed minus one (positive means the model over-predicts). The two
are opposite in sign; a positive value here is an FVS-ACD over-prediction.

## Table 1. Models and configurations tested

| label | base | key settings |
|---|---|---|
| 12.5.0 | production | Weiskittel 2012 mortality, CSI site, hurdle ingrowth (0.95), no self-thinning frontier |
| 12.6.0 | 12.5.0 + site/self-thinning | ESI-capable site, site-independent SDImax, SDImax-ceiling self-thinning |
| 12.6.0 + MORTCAL | 12.6.0 | size-dependent survivor correction on |
| 12.6.1 | 12.6.0 + ingrowth | expected-value recruitment default |
| FVS-NE | external | NE variant (reference; from prior AcdBenchCompare) |

## Part 1. Growth-model bias

### 1.1 Seven Islands CFI, long-horizon (65 routine pairs, by horizon)

Basal-area percent bias (predicted over observed minus one), site held at CSI = 14:

| horizon | 12.5.0 / 12.6.0 (MORTCAL off) | 12.6.0 MORTCAL on |
|---|---|---|
| 5 to 7 yr | -11.3% | -17.2% |
| 8 to 11 yr | +17.6% | +4.8% |
| 12 to 15 yr | +15.8% | 0.0% |
| all | +11.1% | -1.3% |

The signature is a short-horizon under-prediction flipping to a long-horizon over-prediction (+16 to
+18 percent at 8 to 15 years), netting +11 percent. MORTCAL removes the long-horizon over-prediction
(to near 0) but over-corrects the short horizon and deepens the stem deficit.

### 1.2 Stem-count and size structure (Maine FIA, 5 to 7 yr)

| config | BA bias | TPA bias | QMD bias |
|---|---|---|---|
| 12.6.x, MORTCAL off | +3.1% | -8.4% | +6.9% |
| 12.6.x, MORTCAL on | -3.2% | -15.4% | +7.3% |

The model carries too few stems (TPA low) and grows survivors too large (QMD high). MORTCAL worsens
the stem deficit. This is the deficit the 12.6.1 expected-value ingrowth targets.

### 1.3 Site input is a weak lever on basal area

Across the full plausible site range, stand basal area moves about 1 percentage point (Seven Islands
12.5.0 production: CSI 12/15/21 give +11.3/+11.8/+12.7 percent; Maine FIA legacy CSI and ESI
identical to the decimal). Confirmed on both datasets; the ESI swap is safe on basal area.

### 1.4 Version evolution on the NB / NS / ME regional benchmark

The clearest replication of the AcdBenchCompare version comparison: each version run at its
native released configuration on 270 NB/NS/ME remeasurement plots (90 per region, mostly 5 year
intervals), scored on all components. Percent bias, all-region (predicted over observed minus one):

| version | configuration | BA | stems (TPA) | QMD | sawlog MBF | pulp | value $ |
|---|---|---|---|---|---|---|---|
| 12.5.0 | native (0.95 ingrowth gate, no self-thinning frontier) | +6.8 | +6.8 | +1.1 | +7.2 | +7.2 | +8.0 |
| 12.6.0 | + SDImax-ceiling self-thinning, site-independent SDImax | +3.3 | +3.9 | +0.8 | +3.6 | +3.6 | +4.2 |
| 12.6.1 | + expected-value ingrowth | +3.3 | +3.9 | +0.8 | +3.5 | +3.5 | +4.1 |

The result: 12.6.0 roughly halves the over-prediction across every component (basal area +6.8 to
+3.3, value +8.0 to +4.2), and 12.6.1 holds it. This is a stronger improvement than the Seven Islands
CFI alone suggested, and it is informative about where the self-thinning frontier matters: on the
denser regional PSP plots the stands approach SDImax, so the SDImax-ceiling mortality binds and
trims the over-prediction, whereas on the lower-density Seven Islands long-horizon pairs it was
largely inert. The 12.6.0 to 12.6.1 step is flat because, at the 5 to 7 year remeasurement horizon,
recruits have not reached merchantable size (the ingrowth fix shapes long-horizon structure, not
short-horizon merchantable totals).

12.6.1 by region (the operational build): all-region +3.3 percent BA and +4.1 percent value, with a
regional gradient, Maine +11 percent, Nova Scotia +5 percent, New Brunswick -2.8 percent. The bias
is regionally heterogeneous; see the v12.6.1 report section 3.

### 1.5 Pre-v12 version history (Seven Islands CFI)

Extending the version ladder back into the archive (`acd_archive/`), on the 65 routine Seven Islands
CFI pairs, flat CSI = 12:

| version | era | ALL BA bias | 8 to 11 yr | 12 to 15 yr |
|---|---|---|---|---|
| v9.6 | pre-v12 (Russell CSA-growth lineage) | +17.0% | +23.2% | +25.0% |
| v12.1.2 to v12.4.1 | Kuehne increment | +11.0 to +12.1% | (per the v12 archive run) | |
| v12.5.0 | production | +11% (CFI) / +6.6% (regional) | | |
| v12.6.0 / 12.6.1 | self-thinning + ingrowth | +3.3% (regional) | | |

The pre-v12 v9.6 over-predicts basal area more than the modern model (+17 percent vs +11 percent for
the v12 line, and the long-horizon over-prediction is +23 to +25 percent), so the move to the Kuehne
et al. (2022) increment and the later self-thinning work measurably reduced the over-prediction. This
is the long-arc version-evolution result.

Archive caveat: only v9.6 ran cleanly on the Seven Islands tree lists. v8.1 and v10.8 fail on the
legacy species table (their older `SPP.func` rejects several of the species present), running on at
most one plot, and the v11.1 archive file is truncated (unexpected end of input). So v9.6 is the
single representative pre-v12 point; recovering v8.1/v10.8/v11.1 would require repairing the archived
source files and their species tables, which is a data-recovery task separate from this benchmark.

## Part 3. FVS-ACD versus OSM (model-vs-model, long-term)

OSM (Open Stand Model, v2.26.1) was run forward on 79 Seven Islands stands (100-year projection from
the 2023 inventory), with outputs in `OSM/work/silc_100yr_v4/silc_StandListProjections.csv`. Because
this is a forward projection with no observed endpoint, the comparison is model-vs-model on
trajectory shape and level, in the spirit of Ben's long-term-projection section. FVS-ACD 12.6.1 was
projected forward from the same OSM starting inventories (same tree lists, same per-stand CSI).

OSM trajectory (mean across stands):

| age | BA m2/ha | QMD cm | volume m3/ha |
|---|---|---|---|
| 0 | 31.9 | 9.3 | 140 |
| 20 | 36.4 | 12.7 | 191 |
| 40 | 38.8 | 16.1 | 233 |
| 60 | 40.0 | 19.2 | 264 |
| 80 | 40.5 | 22.0 | 283 |

Head-to-head, 9 matched Seven Islands stands (same SurveyID, same starting inventory), mean by age:

| age | FVS-ACD BA | OSM BA | FVS-ACD QMD | OSM QMD |
|---|---|---|---|---|
| 0 | 30.6 | 31.9 | 12.1 | 9.3 |
| 20 | 32.8 | 36.4 | 12.0 | 12.7 |
| 40 | 30.2 | 38.8 | 14.7 | 16.1 |
| 60 | 27.6 | 40.0 | 17.0 | 19.2 |
| 80 | 25.1 | 40.5 | 18.6 | 22.0 |

The two operational Acadian models start matched (basal area about 31 m2/ha) and then diverge
strongly. OSM accumulates basal area to a roughly 40 m2/ha plateau; FVS-ACD self-thins and loses
basal area to about 25 by age 80. By age 80 the two differ by about 15 m2/ha, a 60 percent
divergence, and OSM grows larger trees (QMD 22 vs 19). For long-term yield or carbon projection this
is a first-order disagreement between the two models on the same stands.

The direction is consistent with the rest of this work. These are dense stands (starting near 2,700
stems per ha, QMD about 12 cm, so high relative density), and FVS-ACD both under-grows diameter at
high density (the increment diagnosis found -19 percent at RD 0.8+) and self-thins through its
SDImax-ceiling mortality, so basal area declines. OSM is more growth-optimistic and self-thins less.
There is no observed 80-year endpoint to adjudicate, but the Bakuzis reasoning is that a fully
stocked stand should self-thin (basal area plateauing, not collapsing), so the likely-correct
trajectory sits between the two: FVS-ACD's decline to 25 looks aggressive given its known
high-density growth suppression, and OSM's climb to 40 looks optimistic. The practical message for
the variant decision is that the long-horizon basal-area projection carries large model-form
uncertainty, and the high-density growth and self-thinning calibration (already flagged) is exactly
the lever that controls it.

Caveat: 9 stands projected cleanly through both models on matched SurveyIDs; OSM ran from a 2023
stand-level inventory and FVS-ACD from the same tree lists, so the comparison is matched at the
start. A larger matched set and a merchantable-volume comparison on a common volume definition are
the refinements.

AcdBenchCompare benchmarks FVS-ACD against FVS-NE. FVS-NE is the compiled Fortran variant and cannot
be run in the AcadianGY R harness used here, so the FVS-NE column is not reproduced in this report.
The model documentation records the qualitative result: the Kuehne et al. (2022) diameter and height
increment equations in FVS-ACD are substantially more conservative than FVS-NE, which carries a known
over-prediction expectation in the Acadian region, and FVS-ACD accuracy is reported as greatly
improved over FVS-NE. To complete the FVS-NE column quantitatively, use Ben Rice's existing
AcdBenchCompare FVS-NE runs on the same plots.

## Part 2. Long-term projection reasonableness (Bakuzis)

Modified Bakuzis matrix (Leary 1997) on 150-year site-gradient projections.

| relation | 12.6.0 (even-aged) | 12.6.1 (ingrowth on) |
|---|---|---|
| Height monotone increasing | PASS | PASS |
| Stems monotone decreasing | PASS | FLAG (continuous recruitment) |
| Eichhorn (volume-height site independence) | PASS | PASS (CV 5.1%) |
| Reineke self-thinning slope (target -1.605) | -1.24 (FLAG, improved from -1.08) | -0.52 to -0.67 (recruitment flattens it) |
| Site ordering of height curves | weak (curves nearly coincident) | weak (curves nearly coincident) |

Reading: the self-thinning frontier (SDImax-ceiling) steepens the Reineke slope from -1.08 to -1.24,
closer to the law, while retaining more stems than MORTCAL. Eichhorn passes throughout. Two flags are
informative: the ingrowth-on stems-non-monotone and flat Reineke are the expected consequence of
continuous recruitment (the stand is no longer even-aged, so the even-aged Reineke test does not
apply); and the height site-curves are nearly coincident across the site gradient, meaning the
current site variable barely separates productivity classes. The ESI-anchored dominant-height
prototype removed the height site-ordering inversions (25 to 0), the recommended structural fix and
the natural consumer of a refined ESI.

## Bottom line for the variant decision

12.6.0 improves long-term self-thinning realism and adds a safe, drop-in site input; 12.6.1 fixes the
recruitment-driven stem-count deficit. Neither disturbs the operational basal-area projection on
sub-frontier stands (the self-thinning rarely binds), and the global sensitivity analysis shows stand
value is driven first by the site variable, which makes the refined ESI and the ESI-anchored dominant
height the highest-leverage next step. The long-horizon basal-area over-prediction remains a growth
(increment) issue, not a mortality or recruitment one, consistent with the v12 history in which the
2023 mortality replacement was rolled back to the 2012 equations.

## Files and provenance

- Bias: `results/seven_islands/silc_cfi_v125_full.csv`, `acadgy_fia_remeas_stress.csv`,
  `v126_stress_scorecard.csv`, `region_value_scorecard.csv` (regional, pending corrected run).
- Long-term: `bakuzis_v1261_check.txt`, `bz_v126_reineke.csv`, `bz_v1262_domht_*` (ESI-anchor test).
- Sensitivity: `gsa_v1261_src.csv`.
- Companion reports: `20260628_AcadianGY_v126_report_ben.md`,
  `20260628_AcadianGY_v1261_report_ben.md`; history: `20260629_v12_version_history_and_reversion.md`.
