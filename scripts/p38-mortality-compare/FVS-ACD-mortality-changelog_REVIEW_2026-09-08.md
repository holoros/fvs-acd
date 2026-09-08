# FVS-ACD mortality, changelog and review request

**Date** September 8, 2026
**Prepared for** Ben Rice, Midgard Natural Resources
**Prepared by** Aaron Weiskittel, University of Maine
**Status** REVIEW. All acceptance tests have run and passed.

---

## 0. Read this section first, because the previous state was misrepresented

You wrote that you could not tell what had been done and what the current code is. That was not
a failure of your reading. An audit of the repository against the working machines found that the
state as documented and the state as it exists disagree in five ways, and three of those would
have misled you specifically.

**There is no single production version, and four documents name four different ones.**
`20260628_RECOMMENDED_operational_config.md` says 12.5.0, `20260629_FVS-ACD_production_version_spec.md`
says 12.6.1 in its title and 12.5.0 in its body at line 158, `20260630_production_readiness_verdict.md`
says ship 12.7.0, and `FVS-ACD_variant_overview_GTR_v1211.md` says 12.10.1 is frozen as the
operational release. The only git tag asserting operational status is `v12.7.0-operational`, from
June 30, which is two months stale. The last thing actually frozen and tagged is
`v12.10.1-frozen-aug2026`. v12.11 is a declared release candidate and says so in its own benchmark
report.

**The 13.1 in the repository is not the 13.1 that 14.0 is built on.** The repository holds
`scripts/AcadianGY_13.1_DRAFT.r`, 230,259 bytes, dated July 22, md5 `ff52190d6239df19de5fb172d24aa41c`.
Cardinal holds `~/AcadianGY_13.1.r`, 244,865 bytes, dated August 26, md5 `5894df6013c701d09e7ba67ba6c2f090`.
They are different files six weeks and 14 KB apart, and 14.0's source fallback resolves to the
Cardinal one. Anyone reading the repository to understand 14.0 is reading the wrong base.

**A 13.3 exists that no document in the repository describes, though it is committed.**
`~/AcadianGY_13.3.r` on Cardinal, 261,496 bytes, August 26, `AcadianVersionTag = "AcadianV13.3"`.
It is the hardwood form and risk gap-fill line, and it carries a survival change,
`tsurv_hw_mod_fia`, behind a new sub-flag `ops$use.hw.surv.fia` that defaults to FALSE. It is on
the `hardwood-formrisk-wip` branch as commit `daace79`, "v13.3 (DRAFT): AB/WA growth form/risk
gap-fill from FIA crosswalk; SM survival investigated, not added". So the mortality lineage does
not stop at 13.1 as every prose document implies, and the code is in version control even though
no report mentions it.

*Correction, entered after checking GitHub directly rather than the local clone.* An earlier draft
of this section said 13.3 existed nowhere in the repository. That was wrong, and wrong in an
instructive way: it rested on reading the local working tree, which is behind the remote on this
branch. The remote `hardwood-formrisk-wip` is 74 commits ahead of `main` and 6 behind it, and it
carries work the local checkout does not.

**What is on GitHub is neither the local tree nor a superset of it.** Local HEAD is on
`hardwood-formrisk-wip` with ten unpushed commits dated September 2. Local `main` is *behind*
`origin/main`. A rebase onto `origin/hardwood-formrisk-wip` was started and aborted on September 2
and the divergence was never resolved. This is the direct reason your reading of the fork could not
be reconciled: the code you were looking at is not the code that produced the results.

**14.0 violates the self-containment rule twice.** It `source()`s the 13.1 base at line 104,
through a fallback path that is relative and therefore depends on the working directory, and it
`readRDS()`es a coefficient bundle at line 142. It is a 424-line overlay that rebinds only
`calc_mortality`; it cannot run standalone, and it is not committed to the repository at all.

Nothing below asks you to accept a number that rests on the above being tidy. Where a result is
inherited from earlier work it is cited to the file that produced it.

## 0a. What is on this branch

Everything the sections below describe is on the branch and directly linkable. The engine and the
two scripts went up in one commit after the byte-exact transfer became available; the line counts
were compared against the remote copy before the write, which is the check section 0b explains.

- Branch: https://github.com/holoros/fvs-acd/tree/mortality-shutoff-repairs-20260908
- Patched engine, `scripts/AcadianGY_12.11.r`, 4,661 lines: https://github.com/holoros/fvs-acd/blob/mortality-shutoff-repairs-20260908/scripts/AcadianGY_12.11.r
- Acceptance tests: https://github.com/holoros/fvs-acd/blob/mortality-shutoff-repairs-20260908/scripts/p38-mortality-compare/acd-12111-parity-and-defect_SCRIPT_2026-09-08.R
- Projection comparison: https://github.com/holoros/fvs-acd/blob/mortality-shutoff-repairs-20260908/scripts/p38-mortality-compare/acd-mortality-three-way_SCRIPT_2026-09-08.R
- The p37 commit whose changes were ported forward: https://github.com/holoros/fvs-acd/commit/2d3ea38
- Parent branch: https://github.com/holoros/fvs-acd/tree/hardwood-formrisk-wip

Your history branch,
`https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/tree/FvsHiHistory`,
was read and is the koa line, not this one.

This branch is cut from the remote tip and carries only the mortality work, which is the reviewable
unit anyway. The ten September 2 commits are a separate matter and are not part of it.

---

## 0b. The patch base, and a near miss worth recording

The repairs below were first written against the local copy of `scripts/AcadianGY_12.11.r`, which
is 4,499 lines. The copy on `hardwood-formrisk-wip` is **4,538 lines**. The 39-line difference is
one commit, `2d3ea38`, "p37: fix two hardwood-lever vectorization defects, unit-proven
behaviour-neutral", from August 26, and the local checkout never received it.

Uploading the locally patched file would therefore have silently reverted that commit. The three
hunks were read from the commit patch and ported forward, so what is offered for review is
**remote base plus `2d3ea38` plus M1 to M3**, at 4,661 lines, and the acceptance tests were rerun
against the reconciled file with identical results. This is the same failure the PR-hygiene notes
already record from `fvs-modern#107`, where a commit that looked like a harmless repeat silently
reverted two real fixes. It was caught here only because the line counts were compared before the
upload rather than after.

**What `2d3ea38` fixed is directly relevant to your report.** Both defects it repairs are silent
discards: `ddbh_hw_mod` was handed whole columns although its leading gate is a scalar `if`, so
under R 4.2 or newer *any stand carrying a hardwood* raised "the condition has length > 1" and was
thrown away by the benchmark runner's per-stand `tryCatch`; `tsurv_hw_mod` then failed the same
way on softwood rows carrying `form` NA. An all-softwood stand projected normally, so the failure
was invisible in aggregate. That is a third member of the same family as M1 and M2: a stand that
quietly leaves the analysis, or quietly stops dying, with no error surfaced to the operator. Worth
knowing about if your NEFF runs have `ops$use.hw.mod` on.

## 1. What changed

### AcadianGY 12.11 to 12.11.1, `scripts/AcadianGY_12.11.r`

Three repairs and one gated lever, all inside the mortality chain, tagged M1 to M3 at their sites
in the source. No fitted coefficient is altered anywhere.

**M1, unknown species codes no longer void a plot's mortality.** The `sp.attr` join in the main
engine has no catch-all row, so a species code outside the 47-row Acadian table leaves `sg` and
`sp.type` as NA. Neither is checked. NA `sp.type` makes `calc_bal` return NA `bal.sw` and `bal.hw`
for every tree below it in the descending diameter list, and NA `sg` propagates through
`cumsum(expf * (0.00015 + 0.00218 * sg) * ...)` into `ba.growth.top30`, which had no `na.rm`, and
from there into `stand.pmort`, the occurrence gate, and `dexpf`. The apply site then reads
`dplyr::coalesce(dexpf, 0)` and converts the whole failure into "no mortality", silently, for the
whole projection.

The repair is a named helper, `fill_unknown_sp_attr`, called immediately after the join. Unknown
codes take the other-hardwood attributes, which is the convention `validate_acd_tree_spp` already
applies, and the substitution raises a warning naming the codes rather than passing silently.
`ba.growth.top30` also gains `na.rm = TRUE`, which brings it into line with the balsam fir summary
twenty lines below it that already had it.

**This is the repair most likely to explain what you are seeing on FIA plots**, because the FIA
species list is far wider than the Acadian table and the failure is deterministic per plot: one
unrecognised stem anywhere in the list is enough.

**M2, the stand occurrence gate, behind a switch, default off.** The gate is the hurdle model's
classification form rather than its expectation:

```r
stand.mort.ba = ifelse(stand.pmort > stand.prob.parms$cut, stand.mort.ba * ..., 0)
```

Below the regional cut, which is 0.8720 in Maine, 0.9148 in Nova Scotia, 0.7268 in New Brunswick
and 0.7352 in Quebec, the whole plot takes exactly zero mortality. The concerning part is not the
zero, it is that the gate can latch. In the Maine linear predictor the QMD coefficient is negative
at −0.0551 and the basal area growth coefficient is strongly negative at −2.557, and QMD rises
monotonically through a projection while the growth term stays positive, so a stand that drifts
under the cut tends to stay under it. Once crossed, the projection is growth only for the rest of
the horizon. That is your symptom stated as a mechanism.

The repair available is the same one v12.6.1 already applied to ingrowth, where
`ingrowth.thrshld` moved from a 0.95 hard gate to the expected value of the zero-inflated model.
Here that is `E[mortality] = P(occur) × E[amount]`. It is switched by
`ops$mort.expected.value` and **defaults to FALSE**, so shipped behaviour is the hard gate
unchanged and every existing benchmark stands. It is offered for your judgement, not enabled.

**M3, the tree allocation.** `sum(tree.mortba)` gains `na.rm`. The ratio is guarded against the
weight sum being zero, which happens when every tree's survival probability saturates at exactly
1.0 in double precision, a real case for small stems of species with large intercepts such as SB
at 44.2565; the old code computed `tree.mortba / 0`, produced `NaN`, and the `coalesce` at the
apply site dropped the mortality. When the ordering weights are all zero the stand rate is now
spread on basal area instead, so the stand total the equations asked for is delivered rather than
discarded. `mort.mult` is coalesced to 1 so a species missing from `calib.spp` cannot zero its own
mortality.

M3 is algebraically identical to 12.11 whenever the weights are positive and nothing is NA. The
old code computed `mort.ratio = sum.tree.mortba / stand.mort.ba` then
`tree.mortba / mort.ratio`, which is `stand.mort.ba * tree.mortba / sum.tree.mortba`; the new code
computes that product directly. Parity on clean input is therefore exact by construction, and it
was also measured, see AT-1 below.

### Not changed, and why

**Ingrowth.** You reported that the cutpoint has to go far below the default to get any ingrowth.
That is confirmed, and it is worse than a tuning problem, but the shipped default is already
correct so there is nothing to repair in the engine's behaviour. Under the GNLS coefficients the
occurrence probability is
`plogis(-0.2116 - 0.0255·BA - 0.1396·pHW - 0.0054·(TPH/1000) + 0.0433·CSI + 0.0409·MinDBH)`.
QMD drops out, its coefficient is 0. Only CSI and MinDBH push the logit up. The absolute ceiling
over any physically meaningful stand is about **0.71**, and a typical Acadian stand sits at
**0.45 to 0.50**. The 0.95 default is therefore **outside the attainable range of the function**:
it is not a strict filter, it is identically zero on every plot-year. Clearing 0.95 would need
CSI near 68 m at zero basal area.

The count side is fine. A typical stand gives `exp(eta) = 29.3` stems ha⁻¹ yr⁻¹ against 39.8
observed in New Brunswick, so the model under-predicts by roughly a factor of two, not by a factor
of infinity.

`make_ops()` has shipped `ingrowth.thrshld = 0`, the expected-value form, since v12.6.1. So if you
are getting no ingrowth at the default, you are almost certainly hitting one of three things, and
it is worth knowing which:

1. running a legacy 12.3.x engine, whose `AcadianGYOneStand` default is `CutPoint = 0.95` and
   whose `Ingrowth.FUN` missing-argument fallback is 0.9995;
2. building an `ops` list by hand rather than calling `make_ops()`;
3. reading the roxygen, which still says `@param ingrowth.thrshld Numeric: Ingrowth threshold
   (default 0.95)` while the code two hundred lines below sets 0.

The Seven Islands harnesses in `scripts/seven_islands/` build `ops <- list(verbose=FALSE,
INGROWTH="Y", MinDBH=5.0)` with no CutPoint, so they inherit the legacy 0.95. That answers "what
Seven Islands is using": 0.95, inherited rather than chosen. Its provenance is a comment in v11.1,
"Ian has done testing and found 0.95 works well for CutPoint".

The two documentation defects, the roxygen and the `prob_ingrowth` formal default of 0.95, are
**left unrepaired pending your call**, because changing a stated default is the kind of thing that
should not be done to a collaborator without warning. Say the word and both go.

One earlier result should be treated as a false negative rather than evidence:
`20260628_acadiangy_mortality_ingrowth_calibration.md` reports ingrowth multipliers of 1.0, 0.5 and
0.0 giving byte-identical predictions, and attributes it to the multiplier not being plumbed
through. Scaling zero by anything gives zero, so an unreachable cutpoint explains it at least as
well.

---

## 2. Directions explored since the previous production version

**Density-dependent self-thinning as a second mortality source.** The SDImort ramp runs on relative
density with onset 0.30, hinge 0.62, gentle slope 0.02 and steep slope 0.80. It is a second,
independent removal on top of the base chain, and it has its own zero paths: relative density
below onset, an NA `sdimax` from an unmatched plot key, and a hard `dbh >= 10` filter that makes
an all-sapling stand structurally incapable of self-thinning.

**Hierarchical posteriors, 13.1.** A `mort_hier_g` multiplier on the self-thinning fraction, with
a Jensen aggregate-neutrality normaliser added July 28 because a log-link modifier centred on the
training mean is pointwise 1.0 but not population-mean 1.0. Default off and pinned to 1.0.

**Hardwood form and risk survival, 13.3.** `tsurv_hw_mod_fia`, a clamped cloglog hazard-ratio form
fit on the Maine FIA GRM crosswalk at n = 15,881, behind `ops$use.hw.surv.fia`, default FALSE.

**The three-stage linked survival system, 14.0.** Stage 1 a binomial cloglog stand occurrence with
`log(dt)` offset, stage 2 a profile density fit, stage 3 a species-level allocation, with a
betabinomial floor and three linkage modes L1, L2 and L3. Fitted with Maine excluded, so
jurisdiction ME is evaluated at the population level. This is a genuine replacement for the whole
chain rather than a modifier: when the lever is on it sets `ops$use.sdimort <- FALSE` and becomes
the only mortality in the model.

---

## 3. Validation results

### 3.1 The Bakuzis comparison, and it does not favour the newest model

Source: `active-projects/fvs-acd-survival/bakuzis-comparison-reineke-standardised_DATA_2026-09-08.csv`,
produced September 8 under the `08b` self-thinning filter, a cell required to carry at least five
thinning steps and a non-constant QMD to contribute, with a nonparametric percentile bootstrap of
the median over contributing cells at 10,000 resamples.

Reineke's rule puts the self-thinning slope near **−1.605**.

| Formulation | Median slope | 95% bootstrap | Contributing | Frontier crossings | Max BA, m² ha⁻¹ |
|---|---|---|---|---|---|
| v12.11 SDImax ON | −1.736 | [−1.936, −1.560] | 15 of 15 | 0 | 40.8 |
| v13.1 SDImax ON | −1.736 | [−1.936, −1.560] | 15 of 15 | 0 | 40.8 |
| v13.1 SDImax ON + hier | −1.903 | [−1.963, −1.604] | 15 of 15 | 0 | 40.4 |
| v12.11 / v13.1 SDImax OFF | −1.856 | [−2.106, −1.525] | 12 of 15 | 8 | 197.5 |
| **v14 L1** | **−0.783** | [−1.038, −0.557] | 15 of 15 | 10 | 79.9 |
| **v14 L2** | **−1.113** | [−1.255, −0.942] | 15 of 15 | 4 | 73.4 |
| **v14 L3** | **−0.695** | [−0.893, −0.449] | 15 of 15 | 10 | 79.9 |
| OSM-ACD v2.26.1 | −0.915 | [−1.997, −0.852] | 4 of 9 | 0 | 60.2 |

Three things follow, and the second is the one that matters.

**v12.11 and v13.1 are the same model on this axis.** Identical to every reported digit wherever
the switches match. That is expected, since the mortality block is the same code offset by 139
lines, and it is worth stating plainly because the version numbers imply a difference that is not
there.

**The linked system is the only family whose interval excludes Reineke's slope in the shallow
direction, and by a wide margin.** v12.11 and v13.1 with SDImax on bracket −1.605 comfortably.
v14 L2, the best of the linked family, tops out at −0.942, and L1 and L3 do not reach −1.04. These
are self-thinning slopes roughly half of the law-like value, on 15 of 15 contributing cells, so
this is not a coverage artifact. The frontier crossing counts and the maximum basal areas say the
same thing from the other side: L1 and L3 cross the size-density frontier on 10 of 15 trajectories
and run basal area to 79.9 m² ha⁻¹, which is far above any observed mature Acadian stand.

The Bakuzis test falsifies, it does not confirm. It does not say the linked model predicts worse;
its held-out proportional Brier score is 0.043564 and it may well be the better short-horizon
predictor. It says that whatever the linked model is doing, it is not reproducing self-thinning,
and a model that does not self-thin should not be projected to rotation length.

**A caution on the shipped bundle.** The bundle's stage 3 is flagged PROVISIONAL in the script
that builds it, `R/24_v14_coef_bundle_v4.R` line 96, "version 2 frame, superseded if the
whole-frame refit differs". The whole-frame refit has since happened.

### 3.2 Acceptance tests on 12.11.1

Script `scripts/p38-mortality-compare/acd-12111-parity-and-defect_SCRIPT_2026-09-08.R`, run on the
committed 12.11 and the patched 12.11.1 side by side in isolated environments.

| Test | What it asserts | Result |
|---|---|---|
| AT-1 | On clean input with the lever off, 12.11.1 reproduces 12.11 | **PASS, exact.** 614.8218070997 stems ha⁻¹ at year 30 under both, maximum absolute difference over 30 years 0e+00 |
| AT-2 | 12.11 loses its mortality on a list containing an unknown species code, 12.11.1 does not | **PASS.** One stem of 40 recoded to `XX`: 12.11 goes from 900.0000 to 900.0000 stems ha⁻¹ over 30 years, losing **zero**. 12.11.1 goes to 614.2379, losing **285.7621**. The warning fires on all 30 years and names the code |
| AT-3 | With `ops$mort.expected.value = TRUE`, mortality is recovered on a stand under the regional cut | **PASS.** Low-density larger-QMD stand, 250 stems ha⁻¹ at 20 to 44 cm: lever OFF loses **0.0000** stems over 30 years, lever ON loses **144.6432** |

AT-2 is the reproduction of your report. A single unrecognised species code on a mid-diameter stem
takes a stand that should lose 285 stems ha⁻¹ over 30 years and gives it exactly zero mortality,
with no error and no warning, for the whole projection. That is "mortality stops and projections
become growth only", stated as a two-line test.

AT-1 passing exactly is the load-bearing one for you, because it means adopting 12.11.1 cannot
move any existing result unless the input contains the defect it repairs.

The first attempt at AT-2 was inconclusive and the reason is worth recording, because it is a
measurement trap rather than a coding slip. The test stand was the AT-1 stand with the unknown
code on the *largest* stem, and both arms lost zero. That looked like a failed repair. It was the
occurrence gate of M2 binding on that stand and zeroing mortality before the NA path could be
reached, so the control arm was already at the floor and the test could not distinguish the two
causes. A test whose control is already at zero measures nothing. Moving the unknown code to a
mid-diameter stem, so that stems both above and below it are exposed to the cumulative sum,
separates them cleanly.

### 3.3 The three engines in the repository are one model at default settings

Independent 150-year projections on a four-point site gradient, CSI 10, 13, 16 and 19, annual step,
script `scripts/p38-mortality-compare/acd-mortality-three-way_SCRIPT_2026-09-08.R`.

At age 100, `scripts/AcadianGY_12.11.r`, `scripts/AcadianGY_13.1_DRAFT.r` and
`scripts/AcadianGY_14.0.r` with its lever off return **identical values on every site and every
variable**, to every digit carried: 19.08, 19.62, 20.18 and 20.82 m top height, 31.35 to 32.59
m² ha⁻¹ basal area, 21.73 to 22.04 cm QMD. Every arm loses 77 percent of its stems and declines in
stem number on 128 to 130 of 150 years, so the mortality chain is live throughout and this is not
a shutoff masking a difference.

This confirms 14.0's own header claim that the lever off is "v13.1 byte for byte", and it
establishes the less comfortable point that the version numbers in the repository do not mark
behavioural differences at default settings. Everything separating 12.11, 13.1 and 14.0 sits
behind flags that default to off.

Site ordering holds: top height and volume increase monotonically with site index at age 100 with
no inversion. QMD is nearly flat across the gradient, 21.73 to 22.04 cm, which is a weak site
response worth a look but is not a Bakuzis violation.

One negative result, reported because it was run. A fourth arm set `ops$mort.cut.scale = 0` as a
stand-in for the expected-value form and returned trajectories identical to the other three. That
is not evidence the lever does nothing; it is evidence the **gate is not binding on dense young
spruce-fir**, which is what that harness starts from. AT-3 shows the gate binding hard on a
low-density, larger-QMD stand. The practical reading is that the latching failure lives on open,
larger-diameter stands, which is what a great many FIA plots are and what a young dense stand is
not.

---

## 4. What is left to explore

1. **Which mortality formulation ships.** The Bakuzis result and the Brier result point in
   opposite directions and both are real. This is a judgement about horizon, not a tie to be
   broken by a single number.
2. **Whether the linked system can be made to self-thin.** Its stage 2 carries its own density
   response, so the shallow slope is a property of that fit rather than an omission.
3. **The v14.0 self-containment rewrite.** Both violations are fixable. The coefficient bundle
   reduces to **249 numeric constants** once the 2,500 bootstrap replicates the lever never reads
   are dropped, which is small enough to inline as literal R at full double precision; a generator
   with an exact round-trip assertion is written as
   `active-projects/fvs-acd-survival/R/35_bundle_to_inline_source_2026-09-08.R`. Inlining the 13.1
   base is mechanical. The blocker is not effort, it is that the base is not in version control.
4. **The two ingrowth documentation defects**, pending your call.
5. **The ingrowth level deficit**, roughly a factor of two after the gate is opened, which is a
   calibration question rather than a defect.
6. **Whether 13.3 and the real 13.1 should be committed**, which is the root cause of this whole
   document.

---

## 5. What I need from you

1. **Confirm which engine you are actually running for NEFF**, by version tag rather than by file
   name, since the file names collide across machines. `AcadianVersionTag` is at line 17.
2. **Push your bug fixes for the uncommon species codes when convenient.** They may overlap M1
   directly, and I would rather merge than duplicate.
3. **Tell me whether to enable `ops$mort.expected.value` by default** or leave it as an opt-in.
4. **Tell me whether to correct the two ingrowth documentation defaults.**

The two uncommitted engines are mine to fix, and the September 2 commits go up as soon as the
machine holding them can run git again.
