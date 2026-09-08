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

## 0a. What is and is not on this branch yet

**This document is currently the only thing on the branch.** The patched engine and the two
scripts described below are written, parsed and tested, but they are deliberately **not uploaded
yet**, because the machine holding them cannot presently run git and the only remaining transfer
route would mean retyping a 4,661-line engine through a browser. Retyping production code cannot
be made byte-exact, and a silently corrupted engine is a worse outcome than a delayed one. They go
up as soon as a byte-exact transfer is available, and this section will be deleted when they do.

So: every measurement below was really run and is quoted from the run, and every file path below
names a real file on the working machines, yet the three code paths will 404 on this branch until
that upload happens.

- Branch, live now: https://github.com/holoros/fvs-acd/tree/mortality-shutoff-repairs-20260908
- The p37 commit whose changes were ported forward, live now: https://github.com/holoros/fvs-acd/commit/2d3ea38
- Parent branch, live now: https://github.com/holoros/fvs-acd/tree/hardwood-formrisk-wip
- Patched engine, PENDING UPLOAD: `scripts/AcadianGY_12.11.r`
- Acceptance tests, PENDING UPLOAD: `scripts/p38-mortality-compare/acd-12111-parity-and-defect_SCRIPT_2026-09-08.R`
- Projection comparison, PENDING UPLOAD: `scripts/p38-mortality-compare/acd-mortality-three-way_SCRIPT_2026-09-08.R`

Your history branch,
`https://github.com/MidgardNaturalResources/ForestVegetationSimulator-Interface/tree/FvsHiHistory`,
was read and is the koa line, not this one.

The ten local commits from September 2 are also still unpushed and are **not** on this branch.
This branch is cut from the remote tip and carries only the mortality work, which is the
reviewable unit anyway.

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
