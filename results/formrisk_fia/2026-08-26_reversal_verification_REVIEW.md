# Independent verification of three claimed reversals against committed fvs-acd statements

Adversarial check, August 26, 2026. Branch `hardwood-formrisk-wip` of `holoros/fvs-acd`, working
copy at `/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd`. Every number below was re-derived
from the primary data or the primary source file. No agent's own script output was accepted as
proof of its own claim. Verification scripts and logs are on Cardinal at
`/users/PUOM0008/crsfaaron/verify_reversal/`.

Confirmation that the disputed text really is committed. `git log --oneline` on the branch shows
`ace37e5`, `75712a0` and `fff00e5` for the Garcia write-up and `0b127c5` and `daace79` for the FIA
crosswalk write-up, and `git status --porcelain` lists neither write-up as modified, so both files
as read are the committed versions. Every file the refit agent produced under `results/formrisk_fia/`
with an `sm_` prefix is still untracked, so none of its output has entered the repository.

---

## CLAIM 1, Garcia extrapolation domain. Verdict CONFIRMED.

**The number.** Of the 2,987 stand pairs that entered the pooled `nlme` fit, 627 carry
`MANAGED = 1`, which is 20.9910 percent. Numerator 627, denominator 2,987, percentage 20.99.
That reproduces the scoping agent's figure exactly.

**Breakdown by source, which the task asked for specifically.**

| Source | Pairs in fit | MANAGED = 1 | MANAGED = 0 | MANAGED absent |
|:---|---:|---:|---:|---:|
| ns | 1,187 | 468 | 719 | 0 |
| ns_long | 1,479 | 159 | 1,320 | 0 |
| mefia_subp | 321 | 0 | 0 | 321 |
| **Total** | **2,987** | **627** | **2,039** | **321** |

Every managed pair originates in the two Nova Scotia sources, none in `mefia_subp`. That is not
because `mefia_subp` is unmanaged, it is because `bench_mefia_subp_pairs.csv` carries no `MANAGED`
column at all. Its columns are `STAND, SITE, PROV, interval_years, ELEV`, and the same is true of
`bench_mefia_pairs.csv` and `bench_mefia_long_pairs.csv`. Since `mefia_subp` is FIA-derived Maine
plot data, and Maine FIA unambiguously samples managed stands, the true managed share of the fitted
pairs is almost certainly higher than 20.99 percent. Treat 20.99 percent as a floor, not a point
estimate, and say so in any amendment.

**Where the filter is, or is not.** There is no management filter anywhere in the chain. The
decisive line is `2026-08-26_garcia_stand_extraction.R:49`,

    m <- merge(m, unique(pr[, .(STAND, interval_years)]), by="STAND")

which selects only `STAND` and `interval_years` off the pairs file and silently discards `MANAGED`
before it can ever be used. Upstream of that, the tree files `bench_<tag>_tree_init.csv` and
`bench_<tag>_tree_t2.csv` are read whole with `fread` and carry no management field to begin with,
their columns being `STAND, PLOT, TREE, SP, DBH, HT, EXPF, YEAR`. I read all four scripts in the
chain, namely the extraction, `2026-08-26_garcia_fortype_prep.R`,
`2026-08-26_garcia_fit_bounded.R` and `2026-08-26_garcia_nlme_restricted3.R`, and none of them
references `MANAGED` at any point. The saved intermediate
`garcia_stand_pairs_with_fortype_2026-08-26.csv` has columns
`STAND, source, H1, N1, H2, N2, interval_years, S1, S2, mort_frac, juris, pct_hw, fortype`, again
with no management field, so the information was gone before the fit stage could have used it.

The omission is not a case of the field being unavailable. The directory
`/users/PUOM0008/crsfaaron/magplot/verify/multisrc/` already holds pre-split files
`bench_ns_pairs_managed.csv`, `bench_ns_pairs_unmanaged.csv`,
`bench_ns_long_pairs_managed_singleregime.csv` and `bench_ns_long_pairs_unmanaged.csv`. Someone had
already done the split. The Garcia chain simply did not use it. Across the full `ns` pairs file the
`MANAGED` split is 2,500 managed against 2,500 unmanaged, and across `ns_long` it is 3,892 against
4,419, so management is not a rare edge case in either source.

**Is the committed sentence wrong, imprecise, or defensible.** Wrong as written. The committed
scope paragraph reads "This pooled curve is fit and validated only for ns, ns_long, and mefia_subp,
natural or lightly-managed permanent-sample-plot networks," and the surrounding text draws the line
explicitly on management, saying the excluded sources "do not belong in that pool at all, not
because of geography or species but because they are actively managed or too sparse to identify."
The restriction that was actually applied was on convergence behavior of the per-source `nls` fits,
which the script itself documents honestly. The restriction was then re-narrated in the prose as a
management criterion it never was. At least 21 percent of the fitted pairs are flagged managed in
the source data, which is a materially different domain claim from "natural or lightly managed,"
and it undercuts the specific argument the write-up builds on Garcia, that managed stands with
divergent thinning histories guarantee only a limiting plane rather than a shared line. That
argument is used to exclude CTRN, PEF and Baxter while a fifth of the retained data has the same
property.

What survives untouched is the statistical result. The pooled coefficients alpha 3.222 with standard
error 0.429, beta 0.0681 with standard error 0.0034 and gamma 5.688 with standard error 0.751, n of
2,987 observations in three groups, are exactly what `garcia_nlme_report_2026-08-26.txt` records, and
nothing in this finding disturbs them. What has to change is the stated extrapolation domain.

---

## CLAIM 2, sugar maple covariate availability. Verdict CONFIRMED, with two qualifications.

**The prior refusal, and what part of it was true.** The refusal recorded in
`_context/handoffs/20260826e_pass36_closed_v133_pending_handoff.md:61` states that "the FIA GRM
population lacks the BAL, plot basal area, and three level form fields `tsurv_hw_mod` needs." The
first half of that premise is verifiably true of the saved extract and only of the saved extract.
The 86 columns of
`/users/PUOM0008/crsfaaron/castle_2017/grm_formrisk/grm_formrisk_analysis_population_2026-08-26.csv`
contain no `BAL`, no `BALIVE`, and no plot basal area column of any name. The functional requirement
is real too. Reading `scripts/AcadianGY_12.11.r:2037` directly, the signature is
`tsurv_hw_mod = function(dbh, bal, ba.plot, form, b0, b1)` and both arguments enter the linear
predictor as `- 0.1232 * bal - 1.4053 * sqrt(ba.plot)`, so they are not optional.

**Independent recomputation of the coverage.** I rebuilt plot basal area and BAL from `ME_TREE`
without reference to the refit agent's script, then compared. Method: take the 15,881 sugar maple
rows of the committed population, resolve each `PREV_TRE_CN` into `ME_TREE` to obtain the
beginning-occasion tree record, take that record's `PLT_CN` as the previous plot visit, and over all
`ME_TREE` rows sharing that `PLT_CN` with `STATUSCD == 1` compute `0.005454 * DIA^2 * TPA_UNADJ`.
Plot basal area is the sum over those trees, and BAL is the sum over the strictly larger diameter
classes on the same visit, computed on diameter groups so equal-diameter ties are handled correctly.

Results, from `claim2.log`.

| Quantity | Value |
|:---|---:|
| Sugar maple rows in the committed population | 15,881 |
| Rows resolving to an `ME_TREE` beginning record | 15,881 (100.0000%) |
| Rows with a non-missing plot basal area | 15,881 (100.0000%) |
| Rows with a non-missing BAL | 15,881 (100.0000%) |
| Rows with plot basal area strictly greater than zero | 15,881 (100.0000%) |
| Beginning plot visits whose live tree list has any missing `TPA_UNADJ` | 0 (0.00%) |

The coverage claim of 100.00 percent on all 15,881 rows is confirmed exactly. The recovered values
are also biologically sane rather than merely non-missing. Plot basal area runs from 0.20 to 66.01
m² ha⁻¹ with a median of 25.04 m² ha⁻¹, and BAL runs from 0 to 58.14 m² ha⁻¹ with a median of 12.60
m² ha⁻¹. BAL is less than or equal to plot basal area on every row, and 865 rows, or 5.4 percent,
have BAL of exactly zero, which is the correct value for a tree that is the largest on its plot.
The beginning-occasion status of the sugar maple tree itself is `STATUSCD = 1` on all 15,881 rows,
so no dead tree is being treated as a live focal tree. The join is genuinely to the previous visit
rather than the current one, since `PLT_CN_BEGIN` differs from the population's own `PLT_CN` on all
15,881 rows.

**On `TPA_UNADJ`. I agree with the refit agent, and the evidence is decisive.** `TPA_UNADJ` in
`ME_TREE` is the plot-design expansion factor, not the population stratum adjustment factor. The
proof is that its values partition exactly on the FIA design breakpoint. Among Maine `ME_TREE` rows,
trees with `DIA` below 5.0 carry `TPA_UNADJ` of 74.9653, and trees at or above 5.0 carry 6.0180.
Those are the FIA design constants and nothing else. A 6.8 ft radius microplot has area
pi times 6.8² of 145.27 ft², four of them give 581.07 ft², and 43,560 divided by 581.07 is 74.966
trees per acre. A 24.0 ft radius subplot has area 1,809.56 ft², four of them give 7,238.23 ft², and
43,560 divided by 7,238.23 is 6.018 trees per acre. Both reproduce to four significant figures. A
stratum adjustment factor would not take exactly two values keyed to the microplot and subplot
diameter breakpoint. There are also secondary values of 4.9925 and 59.9722 on a minority of rows,
which are the same two design factors under an older or slope-corrected plot geometry, and they
preserve the same microplot and subplot split.

Consequence if it had been the wrong factor. It would have been serious but visible. Multiplying by
a stratum adjustment factor, which in FIA is near 1 for the subplot and varies by stratum, would
have produced a plot basal area roughly six times too small on subplot trees and about seventy five
times too small on microplot trees, so the recovered plot basal area would have landed near 4 m² ha⁻¹
rather than 25, and `sqrt(ba.plot)` in `tsurv_hw_mod` would have been understated by a factor of
about 2.4, which propagates straight into any refit coefficient calibrated against it. The realism
check above, median 25.04 m² ha⁻¹ and maximum 66.01 m² ha⁻¹ for Maine, is what rules that out
independently of the design arithmetic. Note further that among live Maine trees the missing rate
for `TPA_UNADJ` is exactly zero, so no silent `na.rm` undercount is in play. The 86,375 missing
values that do exist in `ME_TREE` sit on non-live records and never enter the sum.

**On including competitors later harvested. The refit agent is correct, and the point is stronger
than it stated.** Of the 124,923 live beginning-visit trees on the sugar maple beginning plots, the
GRM component classification of their own subsequent fate is as follows.

| Later fate, `SUBP_COMPONENT_AL_FOREST` | n |
|:---|---:|
| SURVIVOR | 78,443 |
| NOT USED | 32,769 |
| CUT1 | 6,620 |
| MORTALITY1 | 5,504 |
| INGROWTH | 1,120 |
| no GRM record | 341 |
| DIVERSION1 | 106 |
| CUT2 | 17 |
| MORTALITY2 | 2 |
| DIVERSION2 | 1 |

Building the competition covariate from `ME_TREE` at the previous visit is the correct construction
and building it from the restricted GRM population would not be. It is correct on two grounds.
First, competition at the beginning of the interval is a property of the stand as it stood at that
moment, and a tree that was alive and occupying growing space then exerted that competition
regardless of what happened to it afterward. Second, and more important, restricting to the GRM
survivor and mortality population would make the covariate conditional on the future. Only the
SURVIVOR, MORTALITY1 and MORTALITY2 rows survive that restriction, so 6,637 later-cut trees, 107
diversions, 32,769 NOT USED rows and 341 unmatched rows would drop out, which is 39,854 of 124,923
trees, or 31.9 percent of the beginning-visit live stand. Worse, the drop would be selective on
outcome, since whether a competitor is retained would depend on whether it was later harvested. That
is exactly the leakage a beginning-of-interval covariate exists to avoid, and it would bias BAL
downward preferentially on plots that were later cut, which are also the plots where sugar maple
mortality behaves differently.

**Qualification one, unresolved and material.** The recomputation includes microplot trees, meaning
live stems from 1.0 to 4.9 inches carrying `TPA_UNADJ` near 75. That is defensible, and matches FIA's
own `COND.BALIVE` convention of all live trees at or above 1.0 inch, but it is a choice and it is not
the only one. It has not been checked against what basal area Castle's original `tsurv_hw_mod`
calibration used. Since a 1.0 inch stem expands to about 75 trees per acre, the microplot contributes
a non-trivial share of the total, and a mismatch against the calibration basis would bias the
modifier. This needs to be settled before any coefficient is fit, and it is not settled by anything
verified here.

**Qualification two.** The refit agent's reversal addresses only two of the three fields the original
refusal named. The third, the form class system, is untouched by the claim. Reading
`AcadianGY_12.11.r:2040` through `2051`, `tsurv_hw_mod` accepts `F1`, `F2`, `F5` and `F8` and maps
them to `STM`, `SWP`, `MST` and `OTHER`, of which only `STM` and `SWP` carry live indicators at
3.3082 and 2.2518. The FIA crosswalk emits only `F1` and `F2`, which do map onto exactly those two
live indicators, so the mismatch is less damaging than the handoff's phrase "three level form
fields" implies. Nonetheless the handoff sentence is imprecise on this third point in a different
direction than the other two, and the amendment should not silently roll all three together as
though one finding disposed of all of them. Also worth recording, `tsurv_hw_mod` takes no risk
argument at all, so risk is not part of this question.

**Unit trap, flagged because it connects to Claim 3(c).** The raw expression
`0.005454 * DIA^2 * TPA_UNADJ` yields ft² acre⁻¹, not m² ha⁻¹, since 0.005454 is the imperial foresters'
constant valid only for diameter in inches. The engine is metric, and inspection of the coefficients
confirms it, since `1.4053 * sqrt(ba.plot)` with basal area near 25 m² ha⁻¹ contributes about 7.0 to
a logit with an intercept of 15.1991, while the same term on ft² acre⁻¹ near 109 would contribute
14.7 and swamp it. The conversion factor is 0.2295684. The refit agent's own build script
`sm_build_analysis_frame_2026-08-26.R:87` does carry the conversion and the comment, so this is a
note rather than a defect, but any amendment must state the units explicitly.

---

## CLAIM 3, four propagated numeric errors.

The primary evidence is the run log of the committed fit itself, job 13978142 at
`/users/PUOM0008/crsfaaron/castle_2017/grm_formrisk/grmformrisk_13978142.out`, which is the log of
the very script that produced the committed write-up, plus my own recomputation from the saved
142,603-row population.

### 3(a), population size and plot count. Verdict CONFIRMED for the row count, CONFIRMED and worse for the plot count.

The run log line 5 reads `Analysis population after filters: 142603 rows (of 756788 GRM rows)`, and
line 19 of the same log gives the component breakdown as `MORTALITY1 7957` and `SURVIVOR 134646`.
My independent read of the saved population CSV returns exactly the same figures, 142,603 rows split
7,957 and 134,646. So 134,646 is the survivor count and the analysis population is 142,603. The
committed write-up's sentence, "The analysis population is every SURVIVOR, MORTALITY1 or MORTALITY2
record ... 134,646 trees on 8,973 plots," names the population correctly in words and then reports
the survivor subtotal as its size.

The arithmetic downstream confirms the confusion is real rather than a typo. The write-up reports
the growth model at n of 134,449 and says 197 rows were dropped. That is 134,646 minus 197, so the
write-up subtracted the growth exclusions from what it had already called the whole population, which
only works if the population and the survivor count were being treated as the same object. The
mortality model was in fact fit on `d`, all 142,603 rows, which the code at
`build_and_fit_2026-08-26.R` makes unambiguous. This error propagated verbatim into
`_context/handoffs/20260826d_pass36_plus_fia_formrisk_handoff.md:16` and, more damagingly, into
line 20 of that same file, which states the mortality model was fit at `n=134,646`. That statement
is false. The true mortality model n is 142,603.

The plot count is worse than a mislabel. It is not reproducible from the committed script and data at
all. I computed every plausible candidate.

| Candidate | Distinct plots |
|:---|---:|
| Full analysis population, current visit `PLT_CN` | 11,246 |
| Full analysis population, previous visit `PLT_CN` | 11,246 |
| Survivors only | 11,164 |
| Growth-fit subset | 11,161 |
| Mortality records only | 4,344 |
| Union of current and previous visits | 14,251 |
| Rows with `DIA_BEGIN` at or above 12.7 | 5,199 |

None of these is 8,973, and no combination of the species-level plot counts produces it either. The
refit agent's figure of 11,246 is correct and I reproduce it exactly. Where 8,973 came from could not
be established. It should be treated as unsourced and replaced, not reconciled.

### 3(b), crosswalk coverage. Verdict PARTIALLY CONFIRMED. Both numbers are real, they measure different things, and the committed sentence describes the wrong one.

This is not a straightforward error, and the amendment should not call it one. The run log of the
committed fit, line 3, reads
`Coverage of the crosswalk on hardwood rows in ME_TREE: form 83.38%, risk 90.46%`. That is the same
script that produced the write-up, printing 83.38 and 90.46 for a denominator of all Maine hardwood
rows in `ME_TREE`, which I confirm is 440,065 rows with `SPCD >= 300`. The refit agent's figures are
therefore exactly what the committed run itself produced.

The 98 and 100 figures are also real, and I traced them to their source. They come from the earlier
pass at
`/users/PUOM0008/crsfaaron/magplot/verify/formrisk_crosswalk/apply_cw.out`, whose `rep_cov` function
at `apply_formrisk_crosswalk.R:123` defines its denominator as
`nhw <- sum(!is.na(m$risk) | !is.na(m$form))`, meaning hardwood rows that already carry a form call
or a risk call. On the init pass that denominator is 236,769. Form calls are 198,760 F1 plus 33,720
F2, giving 232,480, and 232,480 divided by 236,769 is 98.19 percent. Risk calls are 210,157 R1 plus
19,539 R2 plus 7,073 R3, giving exactly 236,769, and 236,769 divided by 236,769 is 100.00 percent.
Both quoted numbers reproduce to the decimal.

So the difference is definitional, not arithmetic. The earlier denominator is conditional and, for
risk, self-referential, since it includes a row only if that row already has a call. Risk coverage of
100 percent under that definition is a tautology rather than a measurement, and it means only that
every row with a form call also has a risk call. The committed write-up describes the number as
"roughly 98 percent form coverage and 100 percent risk coverage on Maine hardwood rows," which
states the unconditional denominator while quoting the conditional figure. That sentence is wrong as
written. The correct statement for the population the write-up is actually describing is 83.38
percent form and 90.46 percent risk. The refit agent's correction is right on substance and slightly
overstated in framing, since the older numbers are not fabricated, they are a different and much
weaker statistic.

### 3(c), the diameter threshold. Verdict CONFIRMED. This is the most serious of the four.

The filter in `build_and_fit_2026-08-26.R` is `DIA_BEGIN >= 5.0`, and the committed write-up renders
it as "a beginning DBH of 5.0 cm or larger." FIA `DIA` is in inches, so the population actually
starts at 12.7 cm, not 5.0 cm. Four independent lines of evidence, any one of which would settle it.

First, and decisively, the design expansion factors partition exactly on 5.0. Across Maine `ME_TREE`,
every row with `DIA` below 5.0 carries `TPA_UNADJ` of 74.9653 or 59.9722 and every row at or above
5.0 carries 6.0180 or 4.9925. As shown under Claim 2, 74.9653 is the four-microplot factor and 6.0180
is the four-subplot factor, and the FIA microplot to subplot breakpoint is 5.0 inches by definition.
A break at exactly 5.0 in a field measured in centimetres would be a coincidence with no design
meaning.

Second, the maximum. `DIA_BEGIN` reaches 43.3. As 43.3 inches that is 110 cm, a large but ordinary
Maine hardwood. As 43.3 cm it is 17 inches, which is an absurd maximum across 142,603 trees.

Third, the height ratio. In `ME_TREE`, live Maine trees have `HT` up to 135 and a median `HT/DIA`
ratio of 6.77. `HT` is plainly feet, since 135 m is impossible. With diameter in inches, 6.77 ft per
inch is a height to diameter ratio of 81.2, a textbook value for forest-grown trees. With diameter in
centimetres it would be 206 to 1, which is physically impossible.

Fourth, internal consistency with the refit agent's own basal area formula. The constant 0.005454 is
valid only for diameter in inches, and using it produced plot basal areas with a median of 25 m² ha⁻¹
that pass a realism check, which they would not if diameter were centimetres.

**Severity.** I agree with the refit agent's flag and would raise it. This is not a labeling defect
confined to prose. It misstates the lower bound of the model's domain of validity by a factor of
2.54, and the same misstatement was carried into the extrapolation domain the write-up asserts. Any
downstream user, or any subsequent session reading the write-up rather than the code, who applies
these modifiers to trees between 5.0 and 12.7 cm would be extrapolating below the fitted range while
believing they were inside it, and the size of that band is precisely the sapling to pole transition
where hardwood mortality and form behave least like the fitted population. Worse, the same unit
confusion applied to `DIA_BEGIN` in the mortality model, which enters linearly, or to `log(DIA_BEGIN)`
in the growth model, would rescale the fitted coefficient directly. The fitted coefficients themselves
are safe, because the code never converted anything and the model was fit on inches throughout, so
the defect is currently confined to the written description. It stops being confined the moment
anyone reads the write-up to set an engine coefficient, and FVS-ACD is metric. Amend the write-up,
the handoff, and any note that carries the threshold forward, and state the units in the same
sentence.

### 3(d), MORTALITY2 records. Verdict CONFIRMED.

The run log's component table lists only `MORTALITY1 7957` and `SURVIVOR 134646`. My own tabulation
of the saved 142,603-row population returns the identical two-level table. There are zero MORTALITY2
records, so the `COMPONENT %in% c("SURVIVOR","MORTALITY1","MORTALITY2")` filter never binds on its
third term and the write-up's enumeration of all three components describes a category that is empty.

This is the least consequential of the four. Nothing in either model changes, since the `MORT`
indicator is built as membership in MORTALITY1 or MORTALITY2 and the second term contributes nothing.
It is worth correcting only because the write-up's phrasing invites a reader to believe the
population spans two distinct mortality components when it spans one. Note for completeness that
MORTALITY2 is not universally absent from the Maine GRM table, since the beginning-visit competitor
tabulation under Claim 2 turned up two MORTALITY2 records among 124,923 trees. It is absent from this
particular filtered population, which is a slightly narrower statement than "zero MORTALITY2 records"
and is the one the amendment should make.

---

## Summary of verdicts

| Claim | Verdict | Number I obtained |
|:---|:---|:---|
| 1, Garcia managed share | CONFIRMED | 627 of 2,987, 20.9910%, all from ns and ns_long |
| 2, sugar maple BAL and BA recoverable | CONFIRMED, two qualifications | 15,881 of 15,881, 100.0000% |
| 3(a), population and plots | CONFIRMED | 142,603 rows on 11,246 plots; 8,973 unreproducible |
| 3(b), crosswalk coverage | PARTIALLY CONFIRMED | 83.38% form, 90.46% risk; the 98/100 figures are a different, conditional statistic |
| 3(c), diameter threshold units | CONFIRMED, highest severity | 5.0 inches, 12.7 cm |
| 3(d), MORTALITY2 | CONFIRMED | zero in this population, two exist elsewhere in ME GRM |

On the question the task posed for 3(a) and 3(b) specifically, whether the discrepancy is an error in
the original or an artifact of a different rebuild. For 3(a) it is an error in the original, and the
evidence is that the committed run's own log printed 142,603 and the write-up printed 134,646, so no
rebuild is involved at all. For the plot count it is neither, since 8,973 corresponds to no build I
could construct. For 3(b) it is a genuine difference between two population definitions, one of which
is the write-up's own run and one of which is a July 17 pass on a different file, and the fault in the
committed text is that it attached the older conditional figure to the newer unconditional
denominator.

---

## What I could not check, and what it would take

The microplot inclusion question under Claim 2 is open. Whether Castle's original `tsurv_hw_mod`
calibration defined plot basal area over all live stems at or above 1.0 inch or only over trees at or
above 5.0 inches determines whether the recovered covariate is on the same basis as the coefficients
it will be plugged into. Settling it needs Castle's 2018 thesis or his fitting code, neither of which
is in `repo_push/fvs-acd`. Until it is settled, the 100 percent coverage result is a statement about
recoverability, not about comparability.

The origin of 8,973 could not be traced. I tested seven candidate definitions and none matched. If
the number came from an interactive session that is not on disk, it may not be recoverable, in which
case it should be deleted rather than reconciled.

I did not re-fit either the growth or the mortality model, so the reported coefficients and p-values
in the crosswalk write-up were not independently verified. Only the population that fed them was.
Re-fitting would take a SLURM job of roughly the same shape as job 13978142 and about five minutes
of wall time, and it is worth doing if any coefficient from that write-up is about to enter the
engine.

I did not verify the Garcia coefficients by re-running the `nlme` fit. I read them off
`garcia_nlme_report_2026-08-26.txt`, which is the fit's own saved output rather than a second
derivation. The fitted object is on disk at `garcia_nlme_fit_restricted3_2026-08-26.rds`, so a
re-fit is cheap if the coefficients themselves ever come into dispute. Nothing in Claim 1 turns on
them, since the claim concerns the domain rather than the estimate.

I did not assess whether the Garcia pooled curve would change materially if the 627 managed pairs
were dropped. That is the obvious next question and it is a re-fit, not a verification, so it was out
of scope here. It would take one Cardinal job of a few minutes, re-running
`2026-08-26_garcia_nlme_restricted3.R` with a `MANAGED` join and filter added, and it would convert
the amendment from a caveat into a result.
