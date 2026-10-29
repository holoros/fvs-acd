# AcadianGY / FVS-ACD version history

Built 13 August 2026 to accompany the 31-file version lineage now in `scripts/` (`AcadianGY_12.3.6.r`
through the current model of record `AcadianGY_13.1.r`). Sourced from the dated handoffs in
`docs/handoffs/`, the model source itself, and Cardinal file metadata; every claim below is
traceable to one of those. Where a detail could not be verified from a primary source it is marked
`[unverified]` rather than guessed. No em dashes.

*Note added October 17, 2026.* The paragraph above dates from August 13, 2026. Eras 7 to 9 have since
added 14.0 to 14.1 and the 14.2 refinement. 14.1 is the current release, and its engine files are on
branch `engines-14.1-20260924` (PR #9), not yet in this branch's `scripts/`. 13.1 remains the model of
record that every 14.x file sources. `docs/reference/running-14.1.md` describes how the layers stack.

## How to read this

Dates are the file's last-modified timestamp on Cardinal (when the version was finalized), not
necessarily when work on it started. Versions marked **shipped** were an actual operational base at
some point; **prototype** versions were exploratory branches that did not become the operational
base; **superseded** versions were replaced before or shortly after reaching production. "Frozen"
means the file is pinned as an unchanging reference point other work is scored against.

## Era 1: v12.3.x, early prototypes (21 to 28 May 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| `12.3.6` | 21 May | 154 KB | prototype |
| `12.3.6_uploaded` | 21 May | 154 KB | prototype (upload copy; checked October 17, 2026: not byte identical to 12.3.6, md5 86b65c71 against a410e66d, and its `AcadianVersionTag` reads AcadianV12.3.5) |
| `12.3.7` | 22 May | 155 KB | prototype |
| `12.3.7_dbg` | 26 May | 155 KB | prototype, debug build |
| `12.3.8` | 26 May | 155 KB | prototype |
| `12.3.9` | 28 May | 156 KB | prototype |
| `12.3.10` | 28 Jun | 158 KB | prototype |

Per `docs/handoffs/20260629_v12_version_history_and_reversion.md`, the Chen et al. (in prep) stand
basal-area increment cap was added at version 12.3.0 and initially applied at the plot level before
being moved to the stand level (a cap on summed tree diameter increment, itself capped at 0.227
percent of plot BA, the 5th percentile of Maine FIA). The 12.3.x line is this refinement's
development arc. Kuehne et al. (2022) diameter and height increment equations (replacing Russell,
Weiskittel et al. 2013/2014) were adopted at 12.1.1, before this repo's lineage starts.

## Era 2: v12.5 to v12.7, production refactor (6 Jun to 30 Jun 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| `12.5.0` | 6 Jun | 176 KB | shipped, production refactor baseline |
| `12.5.0_mortcal` | 8 Jun | 175 KB | variant, MORTCAL enabled |
| `12.6.0` | 28 Jun | 178 KB | shipped |
| `12.6.1` | 28 Jun | 179 KB | shipped, was the README's stated "production candidate" as of late June |
| `12.6.2_proto` | 28 Jun | 180 KB | prototype |
| `12.6.2b_proto` | 29 Jun | 180 KB | prototype |
| `12.6.4` | 29 Jun | 179 KB | shipped |
| `12.6.5` | 30 Jun | 180 KB | shipped |
| `12.7.0` | 30 Jun | 181 KB | shipped |
| `12.7.1` | 30 Jun | 183 KB | shipped |

Per the (now historical) README section: 12.5.0 was the production refactor baseline, with legacy
flags reproducing an even earlier state bit-for-bit. Refinements over that baseline, all gated:
ESI site input, site-independent SDImax, SDImax-ceiling self-thinning, expected-value ingrowth;
MORTCAL optional and off by default (hence the separate `12.5.0_mortcal` variant). 12.5.0 to 12.6.0
roughly halved the regional over-prediction, basal area bias +6.8 percent to +3.3 percent
(`docs/handoffs/20260629_AcadianGY_v126_benchmarking.md` and the README's key findings).

## Era 3: v12.9 to v12.10, operational base and the freeze (1 Jul to 4 Jul 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| `12.9.0` | 1 Jul | 186 KB | shipped |
| `12.9.2` | 2 Jul | 194 KB | shipped, became the actual file behind the frozen "v12.10.1" operational base |
| `12.10` | 2 Jul | 191 KB | shipped |
| `12.10.1` | 3 Jul | 193 KB | **frozen**, the August operational baseline |
| `12.10.2` | 4 Jul | 193 KB | shipped |

This is the most load-bearing entry in the whole lineage and the one detail most worth getting
right. Per `docs/handoffs/20260710_v1210_freeze_and_v13_migration_plan.md`: "the scorecard baseline
`cb_v12102` was produced from `AcadianGY_12.9.2.r` plus a specific ops recipe, not from a standalone
12.10.x file, so 'freeze v12.10.1' means freezing that model-plus-recipe." The shipped model is
`AcadianGY_12.9.2.r` run through `bench_parity.R` with: the ESI-consistent dominant-height anchor
recalibration (`ops$use.esi.anchor.recal`, region coefficients `ops$esi.anchor.coef`, NB
`c(0.885, 0.01027)`, QC `c(0.441, 0.03783)`, applied inside `calc_dht` every year), the brms
composition- and ecoregion-aware SDImax, a region-aware two-segment self-thinning break, a
density-released ingrowth term, and per-province dominant-height afac factors (NB_AFAC 0.579,
QC_AFAC 0.111). The in-domain base scorecard carries an offsetting-bias signature: pooled BA about
-9 percent, top height about +4 percent, TOTVOL about -1.6 percent by cancellation (FIA NSVB, TOST,
Bakuzis). `AcadianGY_12.10.1.r` itself (the file) is the frozen reference used by later Bakuzis
comparisons (for example pass 10's `bakuzis_ship18.R`, which loads `~/_scripts/AcadianGY_12.10.1.r`
as its BASE arm).

## Era 4: v13.0, joint re-anchor, parked (10 to 11 Jul 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| `13.0` | 10 Jul | 196 KB | **superseded / parked**, not adopted |
| `13.0_v2` | 11 Jul | 198 KB | superseded / parked |
| `13.0_wideclamp` | 11 Jul | 198 KB | superseded / parked, widened ESI-anchor clamp variant |

Per the same freeze/migration handoff: the v13.0 joint dominant-height and basal-area re-anchor was
fit on 13,894 ME/NH/VT clean in-domain remeasurement pairs and each component was individually
unbiased (increment ratio 1.00 for both height and net BA). But the height half initially targeted
a code path (`ops$use.esi.domht`) the operational harness has disabled, so it had to be redirected
to the harness-native hook (`ops$use.esi.anchor.recal` / `ops$esi.anchor.coef` inside `calc_dht`).
After that redirect and a BA-fix iteration, the gate runs still failed: the first fixed-BA harvest
inverted the bias (-9.8 percent under to +9.8 percent over, driven by New Brunswick, not Quebec) and
a later fully-fixed run moved the failing axis to the height re-anchor instead. Verdict across all
harvests: **PARK v13.0**. It did not clear the gate on either axis simultaneously. v12.10.1 stayed
the shipped August base. The BA-only correction is preserved in the file for reference but was never
adopted operationally.

## Era 5: v12.11, hardwood fold-in (22 Jul 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| `12.11` | 22 Jul | 215 KB | shipped, hardwood form/risk update |

Per the repo commit history (`04d4064`, "Hardwood plan: fold in Ryan Smith 2022 thesis"): v12.11
folds in Ryan Smith's 2022 thesis, an 8-species hardwood form/risk and product-ratio model set with
usable coefficients. The thesis (Chapter 2) independently found FVS over-predicts hardwood sawlog
volume by 44 to 66 percent, which corroborates this project's own benchmark findings; hardwood
form/risk itself is noted as hard to predict. The thesis PDF is archived in `refs/`.

## Era 6: v13.1, hierarchical refit and the current model of record (15 Jul to 13 Aug 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| `13.1proto_hwmod` | 15 Jul | 196 KB | prototype, hardwood modification |
| `13.1_DRAFT` | 22 Jul | 225 KB | draft, pre-canonical |
| `13.1_PREV_20260725_ingfix` | 25 Jul | 229 KB | superseded waypoint, ingrowth fix |
| `13.1_PREV_20260728_ingnorm` | 28 Jul | 231 KB | superseded waypoint, ingrowth normalizer |
| `13.1` | 13 Aug (current) | 235 KB | **shipped, current model of record** |

Per the freeze/migration handoff, v13.1 (hierarchical mortality and ingrowth refit) initially failed
on two independent problems: a trivial ingrowth code bug and a real mortality convergence
pathology (divergences, treedepth, and low E-BFMI together, pointing at posterior geometry rather
than a simple knob). The dated waypoint files trace the fix sequence: `_PREV_20260725_ingfix` is the
state after the ingrowth code bug fix; `_PREV_20260728_ingnorm` is the state after the ingrowth
normalizer was introduced (the same normalizer whose silent-fallback failure mode pass 9 Track E
diagnosed and pass 11 fixed on 13 August, unrelated to this file's own correctness, since the
normalizer file itself, not the model code, was what went missing at runtime). `AcadianGY_13.1.r`
(current) is the file `~/AcadianGY_13.1.r` on Cardinal, never edited directly since; all subsequent
tuning (ONSET, LEVER 3b, ingrowth multiplier, the ship18 configuration) is applied as overlay
scripts sourced after it loads, per the model-of-record discipline documented in every pass 9
through 11 handoff.

As of pass 10 (12 August 2026, `docs/handoffs` on the `hardwood-formrisk-wip` branch, not yet merged
to `main`), the leading configuration is **ship18**: `sdimort.onset=0.55`, the LEVER 3b
survivor-increment correction, `ingrowth.mult=2.5`, r2 refit. Scored across 10 benchmark sources, 7
of 8 with a prior baseline improve on TOTVOL and basal area bias, one (pef) worsens slightly, and
the Bakuzis biological-realism battery passes 4 of 5 relations (one new flag, softwood Reineke
self-thinning, right at the acceptance boundary, shipped as a disclosed tradeoff). Pass 11 (13
August) fixed a silent-failure defect in the hierarchical-posterior ingrowth path unrelated to
ship18's hand-lever configuration (ship18 never touches the hierarchical posterior switches).

## What this document does not cover

This traces the `AcadianGY_*.r` model file lineage only. It does not repeat the full pass-by-pass
benchmark numbers, which live in the dated handoffs themselves (`docs/handoffs/` for the pre-August
history, `hardwood-formrisk-wip` branch handoffs for pass 9 onward), nor the Zenodo-deposited
v12.10.1 package (`zenodo_v12101/`), which packages that frozen version's data and metadata
separately for citation.

## Era 7: v14.0, the three-stage linked mortality lever (7 Sep to 17 Sep 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| `14.0` | 7 Sep | 22 KB | superseded, first cut of the lever, scored by the pass 23 benchmark |
| `14.0.1` | 16 Sep | 28 KB | superseded, L2 made the default and the stage 3 name map added |
| `14.0.2` | 17 Sep | 37 KB | superseded, three fixes to the lever, all on by default |
| `14.0.3` | 17 Sep | 53 KB | superseded, two further lever repairs and the small-tree increment component |
| `14.0.4` | 17 Sep | 59 KB | **shipped, current v14 release**, the Chapter 10 basal area increment target refitted |

Every file in this era is a derived cut rather than a fork. Each sources the v13.1 base (or the base
named in `ACD_V14_BASE`) and rebinds `calc_mortality` and `make_ops` only; 14.0.3 also rebinds the
diameter increment entry point, behind its own flag and off by default. With
`ops$use.linked.mortality = FALSE`, which is the default, every file reproduces its base exactly.
The lever replaces the SDImax self-thinning block with a three-stage linked system: a plot-level
probability that any stem dies, a Garcia state-space survivor decrement driven by top height with a
stand density index term, and a tree-level stage that ranks which stems die. The coefficients live
in an rds bundle named by `ops$linked.coef.file`. The bundles are in `data/v14/`.

14.0.1 changes three things. L2 (the floor applied as a minimum decrement everywhere) is the default
linkage; L1 and L3 stay available. The stage 3 fixed effects resolve through a documented name map
at bundle load, and the management term is now required. The shipping bundle is
`v14_coef_bundle_2026-09-08.rds` (md5 4740de88af8231677d828dec8e5b753c), with stage 3 refitted on
the version 4 whole frame (601,096 rows) and the genus, family and jurisdiction effects dropped.
14.0 could not load that bundle. With the September 7 bundle, 14.0.1 gives per-tree kill identical
to 14.0 in all three modes. The benchmark numbers for 14.0.1 are in the FVS-ACD linked survival
model report (collected benchmark section, restated 16 September 2026).

14.0.2 (17 September) adds three fixes to the lever, each behind its own switch and all three on by
default. Fix 1 (`ops$linked.fix.threshold`) evaluates the linkage indicator on the stage 1
probability over a reference interval of `ops$linked.threshold.dref` years, default 5, rather than
on the one year probability the engine steps; nu = 0.13 was chosen on the fitted intervals, whose
median is 5. Fix 2 (`ops$linked.fix.floordomain`) applies the floor hazard only where the top height
increment is not positive, which is where it was fitted. Fix 3 (`ops$linked.fix.pool`) computes N1,
the stand state and the stage 3 kill on the closed cohort the stand stages were fitted on, weighting
a recruit that entered k years ago by min(1, k / dref). Diameter growth, height growth, crown
recession and ingrowth are untouched and the coefficient bundle is unchanged. With all three
switches off, 14.0.2 is 14.0.1 exactly in L1, L2 and L3. 14.0.2 was cut and gated on 17 September
but never committed; it enters the repository with this release as `scripts/AcadianGY_14.0.2.r`.

14.0.3 (17 September) makes two further repairs to the lever, changes one default, and adds one new
growth component that is off by default.

Fix 4 (`ops$linked.fix.s3offset`, default TRUE) subtracts the stage 3 centring offset. The stage 3
refit built its design with ldt = log(dt) - 1.687711 and the bundle carries that constant as
`stage3$offset_centre`, but the engine steps one year and added log(1) = 0 without subtracting it,
so every annual stage 3 cumulative hazard ran exp(1.687711) = 5.407 times the fitted one. Stage 3
only allocates a kill that stages 1 and 2 have already sized, so a common shift of the stage 3
linear predictor cancels in the normalisation while the hazards are small, and the defect acts only
through saturation. On the gate stand the uncorrected hazard saturated 124 of 200 stems, from 1 cm
DBH up, which flattened the allocation and pushed the kill onto large stems: the share of the kill
falling on stems 30 cm and larger was 0.1274 under 14.0.2 against 0.0621 under 14.0.3, with the
total kill unchanged at 150.0000 stems. 14.0.1 and 14.0.2 both carry the defect.

Fix 5 (`ops$linked.fix.stepinv`, default TRUE) makes the stand decrement step invariant. The linkage
removes a fraction of the Garcia decrement and both are interval quantities, so chaining one year
steps carried about 30 percent of the fitted interval decrement and L1 removed about 0.3 percent of
stems per year against about 2.2 percent observed. The Garcia log decrement is additive across
years, so the switch applies pi = -log(1 - p(dref)(1 - exp(-L_g))) / L_g to each annual log
decrement l_g, with L_g = dref l_g. At dt = dref that is the fitted interval rule exactly (the gate
agrees to 2.06e-16 on 2,160 rows) and at dref = 1 it is the 14.0.1 arithmetic. It supersedes
`ops$linked.fix.pscale`, and setting both stops.

Fix 2 now defaults off (`ops$linked.fix.floordomain = FALSE`). With it on, L2 is L1, which fails the
size-density frontier and the long-span equivalence test. L2 with the floor applied as a minimum
decrement everywhere is the shipped mode again, so the two labels name two models again.

`ops$use.smalltree.dg` (default FALSE) adds a small-tree diameter increment equation blended into
the large-tree increment between 8.25 and 12.7 cm DBH, FVS style, evaluated at a 5 year reference
interval (`ops$smalltree.iv.ref`). Its coefficients are
`data/v14/smalltree/smalltree_coef_bundle_2026-09-17.rds` (md5
69c423dc3adb142b16aae1bfede0359d), named by `ops$smalltree.coef.file`. With the flag off the
projection is 14.0.3 without the component, which is the identity checked against the mortality-only
intermediate `AcadianGY_14.0.3_mortonly.r` (md5 af33056cd79f93055f5438e001795f10).

14.0.3 also ships `v14_coef_bundle_2026-09-08_L2default.rds` (md5
655ef0117b3531651978f230d82d61fa), the September 8 bundle with `linkage$default` corrected from L1
to L2. Every fitted quantity is identical to `v14_coef_bundle_2026-09-08.rds` and the engine never
reads that field, so either bundle gives the same projection.

Gate results for 14.0.3, 17 September 2026. The lever unit gates pass 14 of 14 and the engine gates
pass 11 of 12. With the lever off, 14.0.3 is v13.1 exactly. With the small-tree flag off it is the
mortality-only cut, with the lever both off and on. At the 14.0.2 switch values it reproduces 14.0.2
in L1, L2 and L3, and with every switch off it reproduces 14.0.2 with every switch off. An unset
linkage mode defaults to L2. Under the 14.0.3 defaults the cohort loses 5.433 percent per year
against 0.912 under 14.0.2 and 5.306 under the 14.0.1 equivalent configuration. The one failure is
C_lev3, which asserts that the LEV3 stand constraint changes the projection and found that it does
not; that gate is unresolved at release and this version makes no claim for LEV3.

Known issue at release. `AcadianVersionTag` in `AcadianGY_14.0.3.r` and in the mortality-only cut
still reads `AcadianV14.0.2`, carried over from the source. The tag has not been bumped.

14.0.4 (17 September, committed 25 September) makes one change. `ops$use.dba.v1404` (`DBA_V1404`,
default TRUE) replaces the Chapter 10 stand basal area increment target that `calc_ddbh`'s
proportional-increment constraint disaggregates. `plot_ba_incr` is rebound rather than edited in
place, so the published equation stays readable in the base and the switch is a true identity when
off. With the switch off 14.0.4 is 14.0.3 bit for bit; with the lever off it is v13.1 exactly.

Why. Measured on the 8,839 stand intervals of the mortality fit frame, the published target has three
defects. Its design is rank deficient, because ln(CSI x RD) is exactly ln(CSI) + ln(RD). Its intrinsic
rate goes negative on 45.0 percent of stand visits between 38.68 and 51.57 m² ha⁻¹ of basal area and
on 98.3 percent above 51.57, which a Verhulst rate cannot do by definition of the form. The target
then collapses to its 0.227 percent floor on 95.2 percent of those visits and 100 percent above
51.57. Predicted over observed survivor basal area increment is 0.705 [0.667, 0.749] pooled and
0.165 [0.148, 0.185] at 38.68 to 51.57. The constraint is a throttle rather than a neutral
disaggregation, and LEV3's activation fractions were not the defect; they only pulled a third of the
frame into a target that was already wrong.

The refit keeps the Verhulst form and repairs it four ways: the intrinsic rate is the exponential of a
linear predictor, the redundant ln(CSI x RD) term is dropped, the predictors are centred, and the
solution is integrated in closed form over each interval on the survivor cohort with a Huber loss of
delta 0.6 m² ha⁻¹ yr⁻¹. The carrying capacity k is fixed at 90 m² ha⁻¹, chosen from a sensitivity
over 80 to 250 as the value minimising the worst basal area class deviation from 1. The shipped
literals are a0 -3.7709501673, a_lrd 0.2315904496, a_lhw -0.0336296628, and centres -0.8557383504 and
-1.5669061229. They are inline in the engine, as the published ones are; the fitting provenance is
`data/v14/dba/v1404_dba_coef_FINAL_2026-09-17.rds` (md5 87c3ba213271d79683415013a58353f3), which the
engine never reads. Predicted over observed moves to 0.947 [0.916, 0.983], four of five basal area
classes cover 1.00, and the floor is reached on 0.000 percent of visits.

Stated limitation. The refitted target does not respond to site index at all. The fit frame excludes
Maine, so its site index spans only 15.58 to 21.18, and a coefficient fitted on that window came out
at 4.374, which extrapolates to 0.17 times the rate at CSI 12 and 4.21 times it at CSI 25. Dropping
the term costs 4.9 percent of training loss and improves held-out transfer from a median absolute
deviation of 0.45 to 0.20. The target responds to density through relative density and the carrying
capacity only. A site term should be restored only on a frame that spans the site index range the
engine actually sees. This is a limitation stated at release, not an oversight.

Gate results for 14.0.4. Nine engine gates pass, including both switch-off identities against 14.0.3.
On the 19 GYDB benchmark sets the switch-off identity holds on all 40 scored rows, with maximum
absolute difference exactly 0 in both %RMSE and bias, on 28,898 admitted rows identical to 14.0.3.
Benchmark assembly gates 310 of 310, H3 19 of 19, Phase D P1 to P3 18 of 18. Four full-engine Bakuzis
gates pass on job 14628037: maximum basal area 43.95 m² ha⁻¹ against the 74.9 bound, zero frontier
crossings of 15 cells in both arms, median basal area at age 160 rising 24.63 to 25.28 m² ha⁻¹, and
Reineke slope -1.779 to -1.807. First-last total volume bias improves from 14.0.3's
-10.548 [-12.023, -9.023] percent to -8.371 [-9.831, -6.864] on NS and from -9.261 [-10.679, -7.780]
to -5.692 [-7.135, -4.158] on NS_LONG, and still misses the plus or minus 5 window, so the E1
benchmark criterion fails and is recorded as such. The pooled survivor diameter increment ratio moves
from 0.7345 [0.7030, 0.7662] to 0.8365 [0.8055, 0.8670], about a third of the gap to 1.00, with every
interval above 12.7 cm still excluding 1.00. Mortality is untouched. The LEV3 defaults arm, run
22 to 23 September, is bit identical to the shipped 0.35 / 0.45 / 18 setting on the Bakuzis grid,
because the grid never reaches densities at which the constraint activates; the shipped setting
stands for want of a guardrail test, and this version makes no claim for LEV3 either way.

Known issue at release. `AcadianVersionTag` in `AcadianGY_14.0.4.r` still reads `AcadianV14.0.2`,
carried over from the source. The tag has not been bumped.

## Era 8: v14.1, option 3 diameter increment terms (23 Sep to 25 Sep 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| `14.1` | 24 Sep | 10 KB | **shipped**, overlay on 14.0.4, both terms off by default, one named standing gate failure (GT1) |

14.1 is an overlay rather than a cut. `scripts/AcadianGY_14.1.r` sources nothing itself; it must be
sourced after `AcadianGY_14.0.4.r` and stops if the 14.0.4 increment hook is not already bound. It
modifies nothing in 14.0.4 and wraps `ddbh`, `calc_ddbh` and `make_ops` the same way 14.0.3 wrapped
them for the small-tree blend. Two switchable diameter increment terms are gated independently, and
each is the identity when its gate is FALSE. With both gates FALSE the hooked engine reproduces the
unhooked 14.0.4 exactly, tree level, in separate R processes (gate E1) and at the 160 yr horizon
(gate E6 leg 1, 15 of 15 Bakuzis cells at a maximum absolute difference of exactly 0).

`ops$use.lsdg.v141` (`LSDG_V141`, default FALSE) is the unmanaged level term L, applied as a
multiplier on the predicted annual diameter increment: m_L(d) = 1 + (lambda - 1) s(d), where s is a
smoothstep from 0 at `ops$v141.d.lo` (12.7 cm) to 1 at `ops$v141.d.hi` (15.0 cm). It is the identity
below 12.7 cm by construction.

`ops$use.thin.v141` (`THIN_V141`, default FALSE) is the thinning release term T, applied after L only
on stands with a known years since thinning: m_T(tst, d, Dq) = 1 + alpha exp(-beta tst)
(min(d / Dq, cap))^gamma, with Dq the quadratic mean diameter of the current tree list and the cap
`ops$v141.rel.cap` set to the maximum d / Dq in the estimation set (gate GT6). The runner contract is
that the caller sets `ops$stand.tst`, the years since the last thinning at the start of the current
step, per stand, and advances it by one each projection year, exactly as it sets
`ops$stand.managed`. When `ops$stand.tst` is NULL, NA or negative, T is not applied to that stand
and the call is counted. T is never applied by guessing a thinning date.

Coefficients come from `ops$v141.coef.file`, an rds written by the offline stage, or from
`ops$v141.lambda`, `ops$v141.alpha`, `ops$v141.beta` and `ops$v141.gamma` when that file is absent.
A gate that is TRUE with no coefficient stops the run rather than falling back to the identity. The
shipped bundle is `data/v14/option3/v141_option3_offline_coefs_r5_2026-09-23.rds` (md5
c8f02f5841e98b93cb532b6fa9b1fc51), from run 14868899, fitted on CTRN and BAXTER, both Maine, with
the bootstrap clustered on the CTRN installation and gamma fixed at 2: lambda 1.14863
[0.92637, 1.37565], alpha 0.37109 [0.12383, 0.64890], beta 0.08220 [0.00752, 0.20480], gamma 2
(fixed, chosen outside the fit as the basal area proportional allocation), relative size cap 2.9848.

Gates. The full pre-registration, with every threshold, its provenance and every revision, is
`docs/v14.1/2026-09-25_v141_option3_engine_gates_PREREG2_r5.md` (md5
1f149a0faadfebc0e640f5ffb129e91e), and it governs. GM0, GL1 to GL5, GT2 to GT6, D1, E1 to E5, E6 and
E7 pass. GT1 FAILS and the failure stands in the record. GT1 requires the implied release half-life
ln(2) / beta to lie between 3 and 50 yr; run 14868899 gives 3.38 to 92.21 yr, so the condition fails
on the upper endpoint alone while the other two conditions of the gate pass (beta's interval is
strictly above 0, and no estimate or interval endpoint sits on an optimiser bound). The band was not
widened and the condition was not retired, because the band is itself a self-referential threshold
that had already been moved once against this fit, and removing a condition because it failed is the
same act with a different name. The diagnosis, so that the failure invites the right repair: the data
determine the SIGN of the release decay and not its RATE. Beta is strictly above zero in every version
fitted and the free gamma fit beats the beta equals zero restriction on objective, so the release
decays. The rate is not identified at the available replication, and the binding constraint is the 17
independent CTRN installations, not the parameter count: fixing gamma removed a bound failure and
left beta's interval essentially unchanged. No further reduction of this functional form will
identify the rate. The condition may be moved only on evidence external to this fit, meaning added
installations or an independently sourced release duration for this species group and treatment. No
document may report GT1 as passing.

The v141 copy of the Phase D runner ships as
`scripts/phaseD/2026-09-25_v141_phaseD_runner_p23_tst.R` on branch `engines-14.1-20260924` (md5 8471121e3a880e838b42923250a94cdd),
because without it a reviewer cloning the repository cannot reproduce a single hooked number. It is
its 14.0.4 parent plus four additive blocks and one changed line: an optional source of the overlay
under `V141=1`, a per stand years since thinning resolved from data with the precedence a per stand
TST column, then a TST_FILE keyed on STAND, then a source level SRC_TST, and the per year advance of
`ops$stand.tst` inside the projection loop. NEVER and UNKNOWN both reach the engine as NA and are
counted apart. With `THIN_V141=1` and no source the run stops. A record whose thinning year equals or
follows the interval start is supplied as UNKNOWN, not 0, because that interval contains the removal
rather than a release. With `V141` unset the file behaves as its parent.

Stated limitations, carried so that they are not rediscovered as defects. Lambda's 95 percent
interval covers 1, so the level term is not separable from the identity at that level; GL1 records
this as a limitation rather than a failure. The relative size class below 0.6 Dq sits at 1.4452
before option 3 and 1.5326 after (run 14868899; an earlier revision quoted 1.5540 from the
superseded r3 fit), the one place the terms made agreement worse; it is out of scope
under GT3 as a 14.0.4 defect for suppressed trees, and widening T to fix it would be tuning against a
symptom. Neither leg of E6 tests T at the projection horizon: leg 1 has no thinning by construction,
leg 2's CTRN intervals are one to two years, and the release observations span only 1 to 17 yr since
thinning. E7 is the only horizon check, and over 50 yr the two terms take the largest projected
diameter from 53.0 to 70.2 cm; that is the size of the commitment and it is invisible at the
remeasurement interval. GT6's cap bound once in 88,703 thinning term calls at the remeasurement
interval and 85 times in 191,800 over 50 yr (corrected on 25 September from an earlier 80,
against the run 14868899 log), so it is load bearing at horizon and nearly inert otherwise. E6 gates CTRN only. Option 3 was fitted on CTRN and BAXTER, both Maine; whether it applies
to the New Brunswick, Quebec and Nova Scotia sources was open when this section was first written. The
regional paragraph below answers it.

Large tree survivor increment, scored after release (25 September 2026). The 14.1 reference was run
through the v141 Phase D runner on all nine Phase D sources. With both gates off it reproduced the
14.0.4 Phase D output file for file, and on the CTRN consecutive source it reproduced the E6 leg 2
output file for file. On the three tag stable sources, CTRN consecutive, CTRN first-last and
BAXTER, 14.1 raises the pooled survivor diameter increment ratio, predicted over observed, from
0.8365 [0.8055, 0.8670] under 14.0.4 to 0.9580 [0.9234, 0.9927]. The classes above 12.7 cm move from
0.7828, 0.7403 and 0.7810 to 0.9129, 0.9201 and 1.0657. A bounded shape only correction for large
trees was pre-registered on top of 14.1 and closed before any fit, because the deficit that remains
is a level deficit in thinned stands, which a shape term normalized over the L estimation set cannot
reach. Three limitations are carried from that work. First, on thinned CTRN stands over 5 to 20 yr
intervals, 14.1 under predicts survivor increment above 12.7 cm (0.8429 [0.7271, 0.9789] on the
first-last source). This is the long interval face of GT1 and stays open until long release records
exist. Second, on the CTRN consecutive source at 5 yr intervals (69 plots in 11 installations), 14.1
over predicts the largest stems: 1.1646 at 30 cm and over, 1.2883 in the 0.6 to 0.85 Dq class, and a
size slope of -0.4443. Third, the tree level frame holds only CTRN and BAXTER, so no leave one
dataset out transfer test of a diameter increment correction is possible on the current data. GT6
has one further data point: on the CTRN first-last source, at 2 to 20 yr intervals, the cap bound 24
times in 49,730 thinning term calls, and relative size reached 3.486.

Regional transfer (25 September 2026). 14.1 was validated as shipped in New Brunswick, Quebec and
Nova Scotia under pre-registration 3, with no coefficient changed. No stand in those regions carries
a thinning year, so T never acts there and the test is of L alone. It was paired against 14.0.4
through one harness whose 14.0.4 arm reproduces the published benchmark file for file. On the
basal area level ratio, all three regions pass. New Brunswick is neutral (0.9887 to 0.9944). Quebec
is neutral on qc_c (1.0261 to 1.0443); qc_fl, with 19 sites, is below the replication floor.
Nova Scotia improves on all four sets, for example ns_long_fl from 0.8574 to 0.8831. The test is
directional. 14.1 raises predicted basal area on 98.9 to 100 percent of stands, so the pass shows
that 14.0.4's basal area under prediction outside Maine shrinks under L. It does not validate L's
size structure there. In Nova Scotia, L also pushes QMD and total volume further above 1, and in
Quebec it moves basal area, total volume and QMD away from 1.

Finalization (26 September 2026, pre-registration 4). On all 19 benchmark sets, the both gates off
arm reproduces the published 14.0.4 benchmark on 62 of 62 chunks. Consecutive frame total volume
%RMSE is within the 0.5 point tolerance: 14.0.4 minus 14.1 is -0.023 (NS) and -0.215 (NS_LONG).
First-last total volume absolute bias falls from 8.371 to 5.411 (NS) and from 5.692 to 2.080
(NS_LONG). The E1 window of plus or minus 5 percent is met on NS_LONG and missed on NS
(-5.411 [-6.933, -3.846]). 14.0.4 missed both. On a new Bakuzis grid, five site indices by four
initial densities (1,500 to 12,000 trees ha⁻¹), each unthinned and with one commercial thinning
from below at QMD 12 cm, all gates pass. The grid runs 160 yr and reaches about 51 m² ha⁻¹. No
relation flags under 14.1 that passes under 14.0.4, and Reineke's Q4 holds in both regimes. This
is the first long horizon test of T. The release it adds decays to nothing by about 17 yr after
thinning, which sits inside the 1 to 17 yr support of the fit. Density feedback then takes part of
it back, and at 160 yr median basal area is 1.1 percent above L alone. One diagnostic, not a gate:
in the 6,000 trees ha⁻¹ thinned cells, T deepens a late rotation top height dip of 0.36 to 0.51 m.
It also produces one top height site order inversion at 160 yr (ESI 16 at 27.12 m against ESI 14 at
27.25 m).

## Era 9: 14.2 refinement and cross-version benchmark (September 27 to October 16, 2026)

| Version | Date | Size | Status |
|---|---|---|---|
| none | 27 Sep to 16 Oct | none | no engine file added, 14.1 remains the release |

Era 9 adds no `AcadianGY_*.r` file. The 14.2 refinement, on branch `v142-refinement-20260926`, ran the
preregistered studies PREREG16 to PREREG45b against the 14.1 benchmark record through rescoring,
offline recomputation or copied runners whose new switches default to 14.1 behavior, and none of
them changed an engine file, coefficient or default of 14.1. It adopted volume scoring under C1 (or
C2 where tags allow) and scorer r2, named one regional NS candidate (v141LTfi) that passes its
benchmark gates but has not cleared a Bakuzis grid, and closed the QC height anchor track with the
shipped 0.111 kept for 14.2. The record is in `scripts/v14.2dev/`, and the release notes are revision
e of October 16, 2026 (`scripts/v14.2dev/2026-10-16/release-notes/`). PREREG46 and revisions 1 to 5
of PREREG47 are registered but not yet run, because firebreather has been unreachable since October
11, 2026.

A cross-version benchmark on October 16, 2026 compared 13.1h, 14.0.4 L2 and 14.1 on the 19 frozen
benchmark sets, 827 post-harvest Maine FIA stands and 200 yr no-harvest projections of 918 unmanaged
Maine FIA stands (`docs/benchmarks/2026-10-16_cross-version/`). Version 14.1 has the smallest median
absolute biomass bias across the 19 sets (3.8%, against 9.6% for 13.1h), but it overstates biomass
recovery after heavy removals by 1.39 Mg ha⁻¹ yr⁻¹ and declines in 64 to 84% of stands in each of the
six named forest types, while 13.1h declines in no more than 2% of stands in any of them. The 14.2 candidate arms p38_fit and qc_rh
were not run, as their engine copies are on firebreather. The benchmark points 14.3 at a thinning
response limited to partial removals, senescence conditioned on forest type, and the diameter growth
shortfall common to every version.
