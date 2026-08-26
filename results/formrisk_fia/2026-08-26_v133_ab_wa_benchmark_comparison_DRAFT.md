# v13.3 AB and WA growth gap-fill, benchmark comparison against v13.1

Working record, August 26, 2026. Scores the two twelve-source SLURM arrays submitted to isolate the
v13.3 American beech and white ash diameter growth form and risk modifier, job 13981173 (baseline,
`AcadianGY_13.1.r`) and job 13981174 (candidate, `AcadianGY_13.3.r`), both under the production
`h2_matgate` configuration with `ops$use.hw.mod` ON in both arms. Companion to
`2026-08-26_fia_crosswalk_formrisk_modifiers_DRAFT.md`, which holds the underlying FIA crosswalk fit,
and to commit `daace79`, which holds the implementation.

**The headline, stated plainly.** The benchmark did not measure the AB and WA effect, and it cannot
measure it as currently built. All twelve source result files are byte identical between the two
arms, but that is not evidence that the change does nothing. It is a consequence of a defect in the
benchmark harness that removes every stand containing a hardwood from the scored population whenever
`ops$use.hw.mod` is ON. The 6,143 stands that survived to scoring contain zero American beech and
zero white ash, so the modifier had no tree to act on. Reporting this as a null result would be
wrong. The correct reading is that the comparison is uninformative about adoption, and the harness
needs a fix before the question can be asked again.

**Both jobs completed.** Every task in both twelve-task arrays reached state COMPLETED with exit code
0:0, confirmed by `sacct` and by directly listing the output directory at
`~/magplot/verify/p_v133/`, where all twenty-four result CSVs and all twenty-four SLURM logs are
present. Elapsed time ran from 21 seconds to 1 hour 4 minutes per task, with the two arms tracking
each other closely, which is itself consistent with the two arms doing identical work.

**Configuration was correct and the arms were matched.** The SLURM logs confirm both arms received
`USE_MODS=TRUE`, the same pairs, tree initialization, tree remeasurement and site files per source,
and the same twenty-odd production lever exports. The candidate arm loaded
`p4e/model_b0b1b2_v133.r` and the baseline arm loaded `p4e/model_b0b1b2.r`, and those two overlay
files are identical except for the single `source()` line naming the base engine, so the b0, b1 and
b2 `ddbh()` patch is the same in both. The deployed `AcadianGY_13.1.r` and `AcadianGY_13.3.r` differ
by 155 changed lines, all of them the v13.3 changelog block, the `ddbh.hw.mod.spp` table extension,
the AB and WA dispatch branch, `ddbh_hw_mod_fia`, `ddbh.hw.mod.fia.spp` and the SM survival decision
comment. Both files carry the v13.1 aggregate neutrality normalizer, so nothing else varies between
the arms. The isolation the design depended on holds, and holds in the strongest available form.

**The result at benchmark level.** Table 1 gives the comparison. Every one of the twelve sources
produced a candidate result file whose MD5 checksum equals its baseline counterpart. There is no
metric to report a delta on, because there is no delta anywhere in any cell of any file, and no
bootstrap or equivalence test was run, since running a TOST on two identical vectors would return a
perfect equivalence that carries no information and would misrepresent what was established.

**Table 1.** Baseline (job 13981173) versus candidate (job 13981174) result files by source, with
the scored and dropped stand counts from each run's own SLURM log. Scored and dropped are identical
between arms, so a single column serves both.

| Source | Scored stands | Dropped stands | Total pairs | Dropped (%) | MD5 agreement |
|---|---|---|---|---|---|
| memat | 61 | 1,696 | 1,757 | 96.5 | identical |
| medev | 201 | 1,558 | 1,759 | 88.6 | identical |
| pef | 144 | 2,709 | 2,853 | 95.0 | identical |
| ctrn | 867 | 219 | 1,086 | 20.2 | identical |
| silc_l | 14 | 59 | 73 | 80.8 | identical |
| nb_v2 | 585 | 1,962 | 2,547 | 77.0 | identical |
| ns_managed | 1,048 | 1,452 | 2,500 | 58.1 | identical |
| ns_unmanaged | 563 | 1,937 | 2,500 | 77.5 | identical |
| ns_long_managed | 1,470 | 1,797 | 3,267 | 55.0 | identical |
| ns_long_unmanaged | 1,076 | 3,343 | 4,419 | 75.7 | identical |
| baxter | 3 | 88 | 91 | 96.7 | identical |
| mef | 111 | 822 | 933 | 88.1 | identical |
| **All sources** | **6,143** | **17,642** | **23,785** | **74.2** | **12 of 12 identical** |

**Why the arms agree, and why that is a harness defect rather than a finding.** The dropped-stand
column is the tell. Three quarters of the benchmark never reached scoring, and the loss is not
random. Cross referencing each source's scored stand list against its tree initialization file
separates perfectly. Across the eight sources checked directly, not one scored stand contains a
species eligible for a form and risk call, and every dropped stand except ten does. For memat the
split is 61 scored stands with no eligible hardwood against 1,699 dropped stands all of which carry
one. For pef it is 144 against 2,709, for medev 201 against 1,559, for ctrn 867 against 219, for
mef 111 against 812 with the remaining 10 lost to the pre-existing fewer-than-three-tree filter, and
the same clean separation holds for baxter, silc_l and nb_v2. A benchmark whose scored population is
defined by the absence of hardwood cannot detect a hardwood modifier.

The mechanism is a vectorization mismatch that only bites when the lever is ON. `calc_ddbh` computes
the modifier with a plain `dplyr::mutate` over the whole tree table, wrapping the call in
`ifelse(!is.na(form) & !is.na(risk), ddbh_hw_mod(...), 1)`. `ddbh_hw_mod` is a scalar function whose
first statement is an `if` over its validity gate, which under R 4.5.2 raises "the condition has
length > 1" as an error the moment it receives a vector. `ifelse` evaluates its `yes` branch only
when at least one element of the test is TRUE, so a stand whose trees are all softwood, and
therefore all carry `form` and `risk` of NA after `split_formrisk`, never triggers the call and
projects normally. A stand carrying even one hardwood triggers it, the error propagates out of
`AcadianGYOneStand`, and the runner's per-stand `tryCatch(..., error = function(e) NULL)` at line
279 of `2026-08-26_p33-matgate-runner.R` discards the stand and increments the failure counter
without printing anything. The failure is therefore silent, identical in both arms, and invisible in
the result files. It is a pre-existing defect in the interaction between `calc_ddbh` and the
benchmark runner, not something v13.3 introduced, and it would have suppressed the six-species
Castle modifier in exactly the same way in any earlier run made with `USE_MODS=TRUE`.

**The control run confirms the mechanism directly.** Rerunning the candidate engine with every export
unchanged except `USE_MODS=FALSE`, submitted as job 13982126, recovers the entire population on both
sources tested. silc_l returns 73 scored stands and zero failures against the 14 scored and 59 failed
the same engine produced with the lever ON, and baxter returns 91 scored and zero failures against 3
scored and 88 failed. Same engine file, same overlay, same inputs, same twenty-odd production levers,
one flag moved, and in both cases every previously discarded stand comes back and nothing fails at
all. The hardwood form and risk lever being ON is precisely what destroys the hardwood-bearing stands,
and turning it off recovers every one of them. This is the control the original two-arm design never
included, and it is the reason the prod-versus-cand comparison could not have detected anything.
Larger-source controls on memat and mef, job 13982044, were still running when this record was
written and are confirmatory rather than load bearing.

**What the isolation check actually shows.** The brief called for direct confirmation that sources
containing no AB, WA or SM score identically between arms. That check passes, and passes twice over.
At benchmark level all twelve sources agree byte for byte, which is a stronger statement than
agreement on the untouched sources alone. At unit level, a direct grid probe over species, form
class, risk class and diameter, run on Cardinal under job 13982039 against both engines loaded side
by side, returns a maximum absolute difference of exactly 0 for red oak, sugar maple, yellow birch,
red maple, paper birch and quaking aspen, confirming the six untouched species are byte identical in
behavior as the commit message claims. Nothing unexpectedly differs. The isolation held. The problem
is that for AB and WA it held vacuously, since the scored population contains none of either.

**What the change does do, measured where it can be measured.** The same unit probe establishes that
the new modifier is live, correctly gated and of the expected magnitude, so the implementation itself
is sound even though the benchmark could not exercise it. Table 2 gives the modifier values against
the v13.1 baseline of 1 for both species. American beech carries a growth penalty rising to 6.5
percent in the worst form and risk cell, white ash carries a growth premium rising to 8.1 percent,
and both are independent of diameter as the model form implies. Neither approaches the [0.5, 1.2]
sanity clamp.

**Table 2.** Diameter growth modifier returned by `ddbh_hw_mod` for American beech and white ash
under v13.1 and v13.3, by form and risk class. Values are invariant to diameter and basal area in
larger trees, verified at 15 cm and 30 cm. Form F5 is shown because the crosswalk collapses it to
the F2 side of the A versus B split, matching F2 exactly.

| Species | Form | Risk | v13.1 | v13.3 | Difference |
|---|---|---|---|---|---|
| AB | F1 | R1 | 1.0000 | 1.0000 | 0.0000 |
| AB | F2 | R1 | 1.0000 | 0.9939 | −0.0061 |
| AB | F1 | R2 | 1.0000 | 0.9872 | −0.0128 |
| AB | F2 | R2 | 1.0000 | 0.9812 | −0.0188 |
| AB | F1 | R3 | 1.0000 | 0.9410 | −0.0590 |
| AB | F2 | R3 | 1.0000 | 0.9353 | −0.0647 |
| WA | F1 | R1 | 1.0000 | 1.0000 | 0.0000 |
| WA | F2 | R1 | 1.0000 | 1.0172 | +0.0172 |
| WA | F1 | R2 | 1.0000 | 1.0551 | +0.0551 |
| WA | F2 | R2 | 1.0000 | 1.0732 | +0.0732 |
| WA | F1 | R3 | 1.0000 | 1.0626 | +0.0626 |
| WA | F2 | R3 | 1.0000 | 1.0808 | +0.0808 |

The benchmark population is not short of the species in question, which is what makes the loss
costly. American beech appears in all ten source tree lists checked and white ash in all ten, with
memat carrying 2,816 beech and 1,291 ash stems, ns_long carrying 2,610 and 1,638, nb_v2 carrying
1,022 beech, and mef carrying 398 and 393. The material to test the change is present in the
benchmark. It is being discarded before scoring.

**Sugar maple survival, restated.** Sugar maple was investigated for the parallel coverage gap on
the survival side, where it has carried no modifier since v12.3.2, and was deliberately not added.
That decision stands and this run does not bear on it either way. The reason is a functional form
mismatch rather than a weak result. `tsurv_hw_mod` is a ratio of two logistic probabilities that
needs per-tree BAL, per-plot basal area and the three-level NHRI form split into STM, SWP, MST and
OTHER alongside a species b0 and b1 pair, and the FIA GRM crosswalk population used to fit the new
mortality model carries none of the three. It has no BAL or plot basal area field, reconstructing
either would need FIA population adjustment factors the extract does not carry and would undercount
competitors on any plot holding a harvested tree, and its form call resolves to two levels rather
than the four the shared equation needs. The new mortality fit is also a cloglog hazard with a
remeasurement period offset against a red maple reference, which is not convertible to the
untransformed logistic on diameter against a paper birch reference that `tsurv_hw_mod` uses. It was
judged not fittable cleanly in the same functional form as the existing five rows and was reported
rather than forced, which is the right call. Sugar maple remains excluded from the survival species
gate, and the survival code for quaking aspen, red maple, red oak, yellow birch and paper birch is
untouched.

One caveat on that restatement. A separate and concurrent sugar maple survival refit was written into
`results/formrisk_fia/` late on August 26, 2026, after commit `daace79` and while this comparison was
being scored, comprising `2026-08-26_sm_survival_refit_DRAFT.md` and roughly seventeen supporting
scripts and coefficient files. Those files were left untracked and were deliberately not committed
here, since they belong to a different thread and were not read or evaluated as part of this run. If
that refit supersedes the not-added decision, the changelog entry in `AcadianGY_13.3_DRAFT.r` and the
paragraph above both need revising, and that reconciliation belongs to whoever owns the refit.

**Verdict.** Hold as experimental. Do not adopt on this evidence, and do not record this run as
having shown no effect, because it showed nothing either way. The implementation is verified correct
at unit level, the six untouched species are provably unchanged, and the modifier magnitudes are
plausible and bounded, so there is no reason to withdraw the code. There is also no benchmark
evidence for or against it, because the only stands that could have carried the signal were silently
discarded before scoring in both arms. The v13.3 changes should stay on `hardwood-formrisk-wip`
behind `ops$use.hw.mod` until the harness is fixed and the comparison is rerun.

**What has to happen before the question can be asked again.** The blocking item is the vectorization
mismatch. `ddbh_hw_mod` and `ddbh_hw_mod_fia` should be called per row, through `purrr::pmap_dbl`
exactly as the `tsurv_hw_mod` call site already does a few hundred lines further down in the same
file, rather than passed vectors inside `ifelse`. The `tsurv` call site is the working template and
the `ddbh` call site is the one that was never converted, which is why the survival lever has never
shown this failure. Two further items follow from it. The runner's per-stand `tryCatch` should count
and report distinct error messages rather than only a bare failure tally, since a 74 percent silent
loss should never have been survivable in a benchmark. And any earlier result produced with
`USE_MODS=TRUE` under this runner should be re-examined, since it was scored on a softwood-only
subset by the same mechanism.

**Repository note.** The `AcadianGY_13.3_DRAFT.r` committed to the branch in `daace79` is not the
file that was benchmarked. The deployed engine at `~/AcadianGY_13.3.r` and the committed draft differ
by 174 lines, and the difference is not in the v13.3 gap-fill, which is identical in both. It is in
the v13.1 hierarchical posterior loader, where the deployed file carries the aggregate neutrality
normalizer added July 28, 2026 and the committed draft does not. The deployed `AcadianGY_13.1.r`
carries the normalizer as well, so both arms of the benchmark were matched and no result here is
affected, but the committed draft should be refreshed from the deployed file so the repository holds
the engine that was actually run.

**Provenance.** Job 13981173 and job 13981174, submitted and completed August 26, 2026, outputs at
`~/magplot/verify/p_v133/`. Unit probe job 13982039, script `~/probe_v133.R`, output
`~/probe_v133_13982039.out`. Control runs job 13982126 on silc_l and baxter, completed for silc_l,
and job 13982044 on memat and mef, both the candidate engine with `USE_MODS=FALSE`, outputs written
alongside the benchmark arms under the `pv133_modsoff_` tag. Harness at
`scripts/p36/2026-08-26_pv133_{prodhw,cand}_array.sbatch`, runner at
`~/magplot/verify/p33/2026-08-26_p33-matgate-runner.R`.
