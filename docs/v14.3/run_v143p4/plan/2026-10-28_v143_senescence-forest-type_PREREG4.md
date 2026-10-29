# Senescence conditioned on forest type, for 14.3: pre-registration 4 (revision 1, registered)

Drafted 28 October 2026 on autopilot. Revision 1 answers the first plan red team (6 MUST, 8 SHOULD, 2 NOTE, `review/2026-10-28_v143-prereg4_REDTEAM_r1.md`); the response table is at the end. This study adds one new arm family to 14.1 through an overlay copy; it edits no 14.1 or 14.2 file, coefficient or default, and no outcome changes 14.1 or 14.2. L and T of 14.1 are not re-estimated and stay at their r5 values; GT1 stays a named failure of 14.1. Frozen runs are read, never rerun. Plot and stand identifiers stay in `*_SERVERONLY` files on OSC Cardinal, no plot coordinates are read, and there are no em dashes. Rates are in Mg ha⁻¹ yr⁻¹, basal area in m² ha⁻¹, diameters in cm. Aaron pre-approved registration with the recommended option for every open choice (section "Plan gate answers").

## Why

The 16 October 2026 cross-version benchmark (`docs/benchmarks/2026-10-16_cross-version/README.md`, Cardinal `~/acdx_20261016/`) grew the 918 unmanaged Maine FIA stands of frame mefia_l_c for 200 yr without harvest. A stand is "declining" there when its biomass at year 200 is below 95% of its maximum over the projection (`2026-10-16_acdx_analyze_r1.R`, part B2). Under 14.1, 64% (spruce-fir) to 84% (elm-ash-cottonwood) of stands decline in each of the six named FIA forest type groups; under 13.1h at most 2.2% of stands decline in any group (white-red pine-hemlock) (`analysis_r1/acdx_long200_peak_decline_DATA.csv`). The Maine FIA aboveground biomass curves (Zenodo 10.5281/zenodo.23406410) give a probability that the curve peaks before 250 yr of 0.906 for spruce-fir and 0 to 0.305 for the other five groups (same file, column `curve_p_peak_before_250`). For stands older than 120 yr the FIA record shows positive net change in spruce-fir (1.41) and maple-beech-birch (1.48), against -0.03 and -0.11 for 14.1 (benchmark README). The Howland projections on the same runner also lose biomass under 14.x over 50 yr (`results/howland_20261026/`). The benchmark README named, as one of three changes for 14.3, that "the senescence that produces the decline in 14.x should be conditioned on forest type, since only spruce-fir declines in the FIA record."

## The mortality lever in 14.0.4 and 14.1

14.1 is the 14.0.4 engine (`AcadianGY_14.0.4.r`, md5 61f95d99) in L2 mode plus the L and T overlay (`AcadianGY_14.1.r`, md5 0bf27dde), which carries no mortality code (`~/jobs/v142p49_lookup_20261026/LOOKUPS.md` on firebreather, item 4). Mortality is a plot-level decrement in `.acd_v14_stand_decrement` (engine lines 504 to 579), allocated to stems by stage 3 (lines 735 to 764):

- a Garcia stage 2 decrement on mean spacing driven by top height growth, with an SDI term (line 550), gated by the stage 1 linkage indicator, giving N2_L1;
- a separate cloglog floor hazard on relative spacing, basal area, Dq, the balsam fir share and the intolerant hardwood share, with offset log(dt) (lines 553 to 559), giving N2_floor = N1 (1 - pf);
- L2 takes the larger kill, N2_L2 = min(N2_L1, N2_floor) (line 579);
- stage 3 spreads the single plot kill over stems by proportional allocation on a per stem cloglog hazard (lines 735 to 764).

## What is known before any fit (exploratory, 28 October, not registered)

Two read-only exploratory readings were made before this plan was written. Neither reads observed mortality or any outcome of a new arm.

**E0, which branch sets the kill** (`explore/e0_branch_explore.R`, job 15945830, output `explore/e0_branch_by_class_age_DATA.csv`). The decrement was re-evaluated on the frozen 14.1 200 yr trajectories (5 yr steps, trajectory TPH, BA, QMD and TOPHT, t1 species shares, dt 5, the 14.0.4 default fixes). Over 36,720 stand steps the share in which the floor kill exceeded the Garcia kill printed as 1 at three decimals (at least 0.9995) in both lever classes and in every 50 yr age bin; the median floor kill was 103 to 175 stems ha⁻¹ per 5 yr against 8 to 25 for the Garcia branch. This is an approximation (trajectory top height is the engine's height-ordered top height, not the lever's diameter-ordered one, and the pool weights are ignored), but the margin is large. **Reading: in these stands the floor is the operative mortality at every age**, so the floor is where a forest type condition can act, and a level shift of the floor changes mortality at every age, not only late in the projection.

**E1, lever class rule** (`explore/e1_class_agreement.R`, job 15945843). Two composition rules for "spruce-fir or not" were compared with the FIA forest type group on the 918 stands (classification only). A plurality rule (spruce-fir group basal area share at least as large as both the pine-hemlock share and the remaining hardwood share) agrees with FIA on 0.879 of stands; a majority rule (spruce-fir share at least 0.5) on 0.877. Under the plurality rule 45 of 164 FIA aspen-birch stands, 38 of 237 maple-beech-birch, 11 of 43 elm-ash-cottonwood and 2 of 45 white-red pine-hemlock are classed SF, and 11 of 370 FIA spruce-fir stands are classed NSF. The plurality rule is registered.

## Hypotheses

- **HS, senescence by type.** A forest type conditioned shift of the floor hazard, fitted to remeasured Maine FIA mortality, brings the share of declining stands in each forest type within the registered tolerance of the FIA curves (spruce-fir declines, the other types mostly do not), without making the ten year hindcast worse than 14.1.
- **HL, late form.** The same shift applied only to stands of large quadratic mean diameter (form S) does this while leaving young stand mortality at 14.1.
- **H0.** The fitted shifts are near zero or of the wrong sign, or do not move the long run behavior into tolerance. Then the decline is not a level error of the floor that ten year remeasurements can see, and 14.3 keeps 14.1's floor; the report says where the evidence points (diagnostic arm D1 below).

## The lever (fixed before any fit)

**Lever class.** At every annual mortality call the overlay computes, from the stand's current tree list (every live record, basal area weighted by expansion), the basal area shares of the spruce-fir group (*Abies balsamea* (L.) Mill., *Picea rubens* Sarg., *Picea glauca* (Moench) Voss, *Picea mariana* (Mill.) Britton, Sterns & Poggenb., *Picea abies* (L.) H. Karst., *Larix laricina* (Du Roi) K. Koch and *Thuja occidentalis* L.; ACD codes BF, RS, WS, BS, NS, TA, WC) and the pine-hemlock group (*Pinus strobus* L., *Pinus resinosa* Aiton, *Pinus banksiana* Lamb., *Tsuga canadensis* (L.) Carrière and other softwoods; WP, RP and its alias RN, JP, EH, OS). The class is SF when the spruce-fir share is at least the pine-hemlock share and at least the remaining (hardwood) share, otherwise NSF. A stand with no live basal area gets no shift. The class is recomputed every year, so a stand can change class as composition changes over 200 yr.

**Forms.** The floor linear predictor etaf (engine line 553) becomes etaf + delta_c · w, with c the class:

| Form | w | Free parameters |
|:--|:--|:--|
| L, level | 1 | delta_SF, delta_NSF |
| S, late | smoothstep of stand Dq from 15 to 25 cm: u = min(max((Dq - 15) / 10, 0), 1), w = 3u² - 2u³ | delta_SF, delta_NSF |

Stand Dq for w is the quadratic mean diameter of the stand's current tree list, expansion weighted. The 15 and 25 cm limits are a prior choice (pole stands and younger keep 14.1's floor, sawtimber stands take the full shift) and are not tuned. The shift is applied by adding delta_c · w to the floor intercept inside a copy of the bundle passed to the 14.0.4 function, so with delta_c · w equal to 0 the engine runs its own arithmetic unchanged. The Garcia branch, the stage 1 linkage, the L2 combination and stage 3 are untouched.

**Overlay.** `AcadianGY_14.3dev_senft.r`, a new file. The caller points V141_FILE at it; it sources the frozen 14.1 file named in V143_V141_BASE (md5 0bf27dde asserted) and then, in the global environment, wraps `.acd_v14_mortality` (to set the class and w for the call) and `.acd_v14_stand_decrement` (to add the shift to the floor intercept and, when tracing, record whether the floor set the kill). Switches: SENFT ("0" identity, default; "1" on), SENFT_FORM (L or S), SENFT_COEF (CSV with CLASS and delta), SENFT_TRACE (optional `*_SERVERONLY.rds`).

## Data

- **Fit set: mefia_l_c fold A.** Folds follow the PREREG11 rule: md5 of the SITE string (digest, serialize FALSE), first hex digit even is fold A, odd is fold B. Fold A is fitted; fold B is held out for every gate on mefia_l_c and on the 200 yr frame.
- **Observed mortality** of a stand (S2: the frame step confirms the t2 lists hold live trees only; any t2 record with EXPF at or below 0 counts as dead): the sum over t1 trees at or above the stand's scoring minimum diameter (SCORE_MINDBH_USED) whose tag is absent from the t2 list, of EXPF · π (DBH / 200)², in m² ha⁻¹ over the interval. Stands with CHURN_FLAG 1 (tag churn) are excluded from the calibration sums and reported.
- **Predicted mortality** of a stand: MORT_BA_S at the last trajectory row of the hindcast run (the trajectory hook's cumulative basal area of stems at or above the same minimum diameter that died, at the start of the year of death; `2026-09-16_gydbreg-phaseD_trajhooks.R`). Because the hook takes diameter at the start of the year of death and the observed sum takes the t1 diameter, predicted mortality is slightly larger in basal area for the same stems; this is common to every arm and is stated as a limit.
- **Benchmark sets:** the 19 frozen sets of the bench141 taskmap, mefia_l_c scored on fold B only.
- **200 yr frame:** the 918 mefia_l_c t1 lists (`long200_mefia_l_c_pairs_DATA_2026-10-16.csv`), gated on fold B, fold A reported.
- **FIA forest type** for the long run gates: FORTYPCD of the first forested condition at the t1 visit, grouped as in the benchmark (SF, MBB, AB, WRPH, OAK, EAC, OTH), joined without coordinates.

## Fit (fold A only; no fold B output exists before the selection record)

**Grid.** Each form is run on the fold A mefia_l_c stands (STAND_KEEP_FILE, the 14.1 environment verbatim) at delta in {-2, -1.5, -1, -0.5, 0.5, 1}, the same delta for both classes, plus one arm g0 with the overlay on, delta 0 and the trace on. g0 is the delta 0 point of both forms and gives the floor domain. Every grid arm uses the same delta for both classes, so a stand that changes class inside its hindcast interval still sees one delta, and per class interpolation stays valid.

**Calibration population, per class.** Fold A stands that ran in every grid arm, are not churn flagged, whose class at t1 (the rule applied to the frame's t1 list) is that class, and in whose g0 trace the floor set the kill in at least half of the plot years. The floor sets the kill in a plot year (one trace call) when fit_ok is FALSE or N1 (1 - pf) is below N2_L1. Form S further requires t1 stand Dq at least 20 cm (w at least 0.5), with Dq from the frame t1 list (all records, expansion weighted). A class with fewer than 30 stands makes the form ineligible.

**Estimate.** For class c and grid point g, R_c(g) = Σ predicted mortality / Σ observed mortality over the calibration stands. delta_c is where log R_c crosses 0, by linear interpolation between the two bracketing grid points. Intervals come from a SITE cluster bootstrap within fold A (1,000 draws) on the same grid outputs. Every bootstrap in this study uses seed 20261028, and 14.1 is rescored with the same seed on the same paired stands.

**Eligibility of a form.** Both classes have a crossing inside [-2, 1]; in each class at most 5% of bootstrap draws have no crossing inside the grid; both classes have 30 or more calibration stands.

**Selection record.** The two forms' coefficients, eligibility and the R tables are written with their md5 before any candidate run. An eligible form becomes a candidate (candL, candS).

## Harness gates

- **H1a.** The overlay sourced with SENFT 0 (arm off) reproduces frozen bench141 v141LT on the 19 benchmark sets: every numeric column of results, per tree predictions, pd files and trajectories, worst absolute difference 0, as the acdx arms check did.
- **H1b.** Arm off reproduces the frozen long200 v141LT outputs on the 918 stand frame, the same way.
- **H2.** Arm g0 (on, delta 0, trace on) reproduces frozen bench141 v141LT on the fold A stands it ran. Because the grid arms run through STAND_KEEP_FILE, H2 (and, for uniformity, H1a and H1b) concatenates the chunk files of each kind and compares by stand on the arm's stand set, with the frozen outputs filtered to it.
- **H3.** The scorer reproduces the frozen bench141 per set scores of v141LT (`score/tables/gyr141-bench-perset-scores_DATA_2026-09-25.csv`) for BA, total volume and AGB within 0.0005 percentage points on every set whose stand count matches, pairing as bench141 did (stands that ran in frozen v141LT and v141off); it fails if fewer than 15 of the 19 sets match on stand count for any metric. It also reproduces the benchmark's FIADB basis ratio (1.0672) within 5e-5.
- **H4.** The class the fit script assigns at t1 equals the overlay's first call class (g0 trace) for at least 99% of fold A stands.
- **H5.** R_c(g) is non-decreasing in delta in both classes and both forms (the lever acts as specified).
- **H7, completeness.** In each of the 19 sets and on the 200 yr frame, every overlay arm runs (RUN_OK 1) at least 99% of the stands frozen 14.1 ran. Every comparison is paired on stands that ran in every compared arm.
- **H6.** No candidate output and no fold B grid output exists before the selection md5 time; every script md5 is in `logs/launch_md5s.txt` before the chain; the assembly md5 is recorded before it runs.

## Gates on a candidate

**Long run (fold B, by FIA forest type, types with 15 or more fold B stands).**

| Gate | Test | Threshold |
|:--|:--|:--|
| LR1 | share declining (year 200 biomass below 95% of the projection maximum) against the curve probability of a peak before 250 yr | absolute difference at most 0.30 in every gated type |
| LR2 | median of projected AGB over the curve at the same age, at year 100 and at year 200 (scaled by the basis ratio) | within 0.67 to 1.50 in every type with 15 or more fold B stands at that year; otherwise reported |
| LR3 | projected net change by age class against observed FIA net change | reported |

**Bakuzis (fold B, as the benchmark's part B4).**

| Gate | Relation | Threshold |
|:--|:--|:--|
| BK1 | magnitude: share of stands whose maximum AGB exceeds the observed 99.9th percentile | at most 0.10 per gated type |
| BK2 | Reineke: share of stands whose maximum SDI exceeds the observed 99.9th percentile | at most 0.05 per gated type |
| BK3 | site ordering: Spearman of ESI with AGB at year 100, 95% stand bootstrap interval | in no type where 14.1's fold B lower limit (recomputed from the frozen long200 v141LT trajectories on the same fold B stands) is above 0 does the candidate's lower limit fall to 0 or below |
| BK4 | Eichhorn: slope ratio of log volume on log top height, high over low ESI tercile | 0.80 to 1.25 |
| BK5 | yield-density: Spearman of initial TPH with AGB at year 100 | absolute value at most 0.20 |

**Ten year hindcast (against frozen 14.1 on paired stands; mefia_l_c fold B only).**

| Gate | Test | Threshold |
|:--|:--|:--|
| HB1 | AGB and BA bias per set, point estimates | absolute bias no more than 1.0 point above 14.1's in each of the 19 sets |
| HB2 | median absolute AGB bias over the 19 sets | no more than 0.5 point above 14.1's |
| HB3 | AGB equivalence (benchmark regions, 1,000 resamples) | passes in at least as many sets as 14.1 |
| HB4 | fold B mortality ratio, predicted over observed basal area mortality, per class | within 0.80 to 1.25 |

**Sensitivity labels.** LR1 is also read at 0.20 and 0.40, HB1 at 0.5 and 2.0 points. A verdict that changes at either is labeled "tolerance sensitive".

**Figure.** Share of fold B stands declining by FIA type for 13.1h and 14.1 (frozen trajectories), each candidate and D1, with 95% stand bootstrap intervals and the curve probability of a peak before 250 yr marked; publication format, no identifiers.

**Limits stated in advance.** (1) LR1 compares a stand's 200 yr projection window, which starts at its current age, with the curve's probability of a peak before 250 yr of age; the two are not the same quantity, which is why the tolerance is wide (0.30) and read at 0.20 and 0.40. (2) 14.1's diameter growth is low on mefia_l_c (QMD bias -6.3 to -12.0% across versions in the benchmark), so the predicted basal area of dying stems is slightly low and the fitted delta is pushed up. (3) The trajectory hook takes diameter at the start of the year of death and the observed sum the t1 diameter. (4) The class rule disagrees with FIA type on about an eighth of stands (E1). (5) E0 is an approximation.

**Diagnostic arm D1 (reported only).** Form L with delta_NSF at -30 (the floor removed in NSF stands, the Garcia branch alone) and delta_SF 0, on the 200 yr frame. It answers whether the floor causes the NSF decline at all.

## Decision rule, in order

1. Any harness gate fails: no verdict.
2. No eligible form: H0 on the fit set; 14.3 keeps 14.1's floor.
3. For each candidate, LR1 or LR2 fails: not adopted, failing types named.
4. HB1, HB2, HB3 or HB4 fails: not adopted, failing sets or classes named.
5. BK1 to BK5 fails: not adopted, failing relation named.
6. All pass: a 14.3 candidate. If both forms pass, L is adopted (it applies at every size and has no threshold) and S is reported.

Nothing in this study changes 14.1 or 14.2.

## Execution

Cardinal, `~/v143p4/` (a new directory). The chain:

1. this plan, red team, registration (`logs/prereg_md5.txt`);
2. scripts and their md5s; dry run on a few fold A stands into `dry/`;
3. frame step: folds, keep files, t1 classes and Dq (SERVERONLY), aggregates only printed;
4. harness arm off on the 19 sets and the 200 yr frame; grid arms on fold A;
5. fit and selection record (md5);
6. candidate arms on the 19 sets and the 200 yr frame, and D1;
7. assembly (md5 recorded first), RESULT with DEVIATIONS and the figure.

Launchers are copies of the bench141 hindcast launcher (`2026-09-25_v142_bench141_array.sbatch`) and the long200 launcher (`cardinal_mcp_job_3936542.slurm`), with the 14.1 environment block verbatim and the runners unchanged (300a0d61, 3d05cbad).

## Plan gate answers (28 October 2026)

Aaron pre-approved the recommended option for every open choice: the plurality class rule; two lever classes (SF, NSF); both forms L and S run, L preferred when both pass; FIA type at t1 for the long run gates; the floor as the component conditioned.

## Response to plan red team 1

| Item | Change |
|:--|:--|
| M1 | E0 restated as printed (share 1 at three decimals, at least 0.9995) |
| M2 | E1 counts given |
| M3 | 2.2% and 0 to 0.305 quoted from the file |
| M4 | H7 completeness gate; all comparisons paired on stands that ran in every compared arm |
| M5 | H3 pairing named; fails below 15 matching sets |
| M6 | Identity checks concatenate chunks and compare by stand |
| S1 | Floor sets the kill defined per plot year |
| S2 | t2 live-only check in the frame step |
| S3 | t1 Dq source named |
| S4 | One seed, 20261028; 14.1 rescored identically |
| S5 | BK3 baseline recomputed on fold B |
| S6 | Limit (1) |
| S7 | Figure specified |
| S8 | Limit (2) |
| N1 | Stated under Grid |
| N2 | Kept |
