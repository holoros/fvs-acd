# AcadianGY / FVS-ACD version history

Built 13 August 2026 to accompany the 31-file version lineage now in `scripts/` (`AcadianGY_12.3.6.r`
through the current model of record `AcadianGY_13.1.r`). Sourced from the dated handoffs in
`docs/handoffs/`, the model source itself, and Cardinal file metadata; every claim below is
traceable to one of those. Where a detail could not be verified from a primary source it is marked
`[unverified]` rather than guessed. No em dashes.

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
| `12.3.6_uploaded` | 21 May | 154 KB | prototype (byte-identical upload copy of 12.3.6, `[unverified]` whether any diff exists) |
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
| `14.0.3` | 17 Sep | 53 KB | **shipped, current v14 release** |

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
