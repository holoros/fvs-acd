# Turning the Garcia (2009) relative-spacing curve into an engine constraint on FVS-ACD stand mortality, a scoping document

Working record, August 26, 2026. Scoping only. No engine file was edited, nothing was committed or
pushed, and no Cardinal job was submitted. Every code line quoted below was read from the model of
record at `/users/PUOM0008/crsfaaron/AcadianGY_13.1.r` on Cardinal, with helper functions read from
the repository copy `repos/fvs-acd/scripts/AcadianGY_13.1_DRAFT.r`, which is byte-identical to the
model of record on every block quoted here except that the model of record additionally carries the
pass 33 maturity-gate insert. Every number attributed to the fitted curve or to the benchmark pair
files was recomputed here from the primary files rather than carried over from the write-up, and the
few that could not be verified are marked as such in the closing section.

The pooled curve under discussion is Garcia's equation 10 with alpha 3.222, beta 0.0681 and gamma
5.688, fit by `nlme` on 2,987 mortality-bearing stand pairs from ns, ns_long and mefia_subp, with
the random effect on beta collapsing to zero. Recomputing the asymptote from the saved coefficients
in `garcia_nlme_coef_restricted3_2026-08-26.csv` gives N(H) = 10⁴ (beta H)^(−2 gamma/alpha) with
2 gamma/alpha = 3.531, and density ceilings of 38,900, 9,290, 3,360, 1,530 and 804 trees ha⁻¹ at top
heights of 10, 15, 20, 25 and 30 m. That reproduces the write-up's 38,800, 3,350 and 800 to
rounding, so the arithmetic is confirmed rather than inherited.

## 1. Where an N(H) ceiling would bind, read from the engine source

`AcadianGYOneStand` advances a stand by exactly one year, and the whole of the density machinery
lives in that one function in a fixed order. The order is what decides where a Garcia constraint
could go, so it is worth setting down before any design question, since three of the four candidate
insertion points are separated only by a few dozen lines yet see completely different tree lists.

The step opens by summarising the incoming list, and the summary is where the engine's own density
currency is defined. In `calc_plot_summary`, at line 3742 of the model of record and line 3599 of
the repository DRAFT,

```r
sdi = sum(ifelse(dbh >= 10, (dbh / 25.4)^1.6 * expf, 0), na.rm = TRUE),
sdi.all = sum((dbh / 25.4)^1.6 * expf, na.rm = TRUE),
```

and `calc_relative_density` then selects between the two on quadratic mean diameter, taking
`sdi/sdi.max` whenever QMD is at or above 10 cm, which is the ordinary case for any stand past the
sapling stage. The consequence is structural and matters more than anything else in this section.
The engine's relative density counts only stems of 10 cm diameter and larger, while Garcia's N, as
extracted in `2026-08-26_garcia_stand_extraction.R`, is `dt[, N := sum(EXPF), by=STAND]` over every
live tree with finite diameter, height and a positive expansion factor, with no diameter floor at
all. The two quantities are not the same variable, and a constraint written in one cannot be read
off the other without a conversion that does not exist in closed form.

After the summary come crown metrics, height and height to crown base, then top height. The engine
already computes exactly the driver a Garcia constraint needs, in `calc_topht` at repository DRAFT
line 3709, as the expansion-weighted mean height of the tallest stems accumulating to 100 trees
ha⁻¹, joined into `plot.smry` and available to every downstream call. One definitional mismatch
should be recorded rather than glossed. `calc_topht` sorts by descending height, `dplyr::arrange(plot,
desc(ht))`, while the Garcia extraction sorted by descending diameter, `setorder(dt, STAND, -DBH)`.
The two agree closely in even-aged softwood and diverge in mixed and irregular structures, so the
constraint would be driven by a slightly different top height than the one the curve was fit
against, an effect that is small yet unquantified.

Diameter, height and crown recession increments follow, and then the two submodels the question
turns on. Base mortality runs first at line 4077, `calc_mortality(plot.data=plot.smry)`, which
predicts a stand-level mortality probability and a stand-level mortality basal area from
`stand_mort_prob` and `stand_mort_ba` and then allocates that basal area across trees, ending at
line 2480 of the DRAFT with

```r
dexpf = ifelse(stand.mort.ba > 0, tree.mortba.adj / ba.tree, 0) * mort.mult)
```

so base mortality is size-differentiated by construction. Ingrowth is computed next at line 4082,
`calc_ingrowth(plot.data=plot.smry)`, and this is where `ops$use.ingrowth.release` acts, at model of
record lines 3050 to 3070,

```r
.ir_on = tryCatch(if (!is.null(ops$use.ingrowth.release)) isTRUE(ops$use.ingrowth.release) else TRUE, error=function(e) TRUE)
if (.ir_on && !is.null(plot.data$rd.mod)) {
  .ir_c = ... else 0.58 ...
  .ir_k = ... else 8 ...
  .rel = 1 / (1 + exp(.ir_k * (dplyr::coalesce(plot.data$rd.mod, 0) - .ir_c)))
  ...
  .mg_on = tryCatch(if (!is.null(ops$use.ingrowth.matgate)) isTRUE(ops$use.ingrowth.matgate) else FALSE, error=function(e) FALSE)
  if (.mg_on) {
    .rel = .rel * (1 / (1 + exp(.mg_k * (dplyr::coalesce(plot.data$qmd, 0) - .mg_qc))))
  }
  plot.data$ingrowth.ph = plot.data$ingrowth.ph * .rel
}
```

Two properties of this block are load-bearing. The release is driven by `plot.data$rd.mod`, which is
the start-of-step relative density computed before any of this year's mortality, so the release
responds to last year's density rather than the density the stand is actually left at. And recruits
are placed at `ops$ingrowth.entry.dbh` where set and at `min.dbh.ingrowth` otherwise, whose
`make_ops` default is 3.0 cm, which is below the 10 cm floor in the `sdi` definition above. A recruit
therefore contributes nothing to the relative density that governs both the release and the
self-thinning ceiling until it has grown seven centimetres of diameter, which at Acadian increment
rates takes on the order of fifteen to twenty-five years.

The tree list is then advanced, `expf = expf - dexpf`, the optional ESI height anchor is applied, and
only then does the self-thinning lever run. `ops$use.sdimort` occupies lines 4138 to 4231 of the
model of record, with the operative arithmetic at 4219 to 4228,

```r
dplyr::mutate(sdm_sdi   = sum(ifelse(dbh >= 10, (dbh / 25.4)^1.6 * expf, 0), na.rm = TRUE),
              sdm_rd    = ifelse(!is.na(sdm_sdimax) & sdm_sdimax > 0, sdm_sdi / sdm_sdimax, 0),
              sdm_mfrac = .sdm_bg * pmin(pmax(sdm_rd - .sdm_onset, 0), .sdm_break - .sdm_onset) + .sdm_bs * pmax(sdm_rd - .sdm_break, 0),
              sdm_mfrac = sdm_mfrac * (...) * mort_hier_g,
              sdm_keepi = ifelse(sdm_rd > .sdm_onset, pmax(0, 1 - sdm_mfrac), 1),
              sdm_keepc = ifelse(sdm_rd * sdm_keepi > .sdm_max & sdm_rd > 0, .sdm_max / (sdm_rd * sdm_keepi), 1),
              ...
              expf      = expf * sdm_keepi * sdm_keepc,
```

Three facts follow directly from those seven lines. First, the engine already carries a hard density
ceiling, since `sdm_keepc` holds post-step relative density at `.sdm_max`, default 1.00, which is a
Reineke-basis ceiling rather than a Garcia-basis one but is a ceiling nonetheless. Second, the
removal is a plot-level scalar applied identically to every tree row inside `group_by(plot)`, so
`ops$use.sdimort` thins the diameter distribution uniformly and removes large-tree volume at exactly
the rate it removes small-tree stems, which base mortality does not. Third, the lever is exactly
inert below `.sdm_onset`, which the pass 32 configuration sets at relative density 0.55, so any
constraint layered onto `sdm_mfrac` inherits that inertness for free.

The step closes at line 4248,

```r
  # Append ingrowth
  if(exists('ingrowth')){
    tree=tree %>%
    dplyr::bind_rows(ingrowth)
  }
```

so this year's recruits are bound in after the ceiling has been enforced and are not subject to it in
the year they appear. Combined with the 10 cm floor, that is the decoupling named in the pass 32
write-up, stated now in terms of the actual lines rather than by inference. Stem count can rise while
neither the relative density that governs the ceiling nor the volume that the ceiling is meant to
protect responds at all.

**Where a Garcia ceiling would bind, measured rather than assumed.** The question of where it would
bind has an answer that can be read off existing trajectory output without running anything. Applying
N(H) to the pass 32 CTRN production trajectory at
`results/bakuzis/data/ctrn_h1default_traj.csv` gives the following, computed here from the saved
coefficients.

**Table 1.** Garcia density ceiling against the pass 32 CTRN long-horizon trajectory, stand
`CTRN_AP_80_I2014_2015`, site index 14.3. N is the engine's simulated stem density and N(H) the
Garcia ceiling evaluated at the same top height. The crash window is ages 40 to 55.

| Age | Top height (m) | N (trees ha⁻¹) | Basal area (m² ha⁻¹) | Volume (m³ ha⁻¹) | N(H) (trees ha⁻¹) | N / N(H) |
|---|---|---|---|---|---|---|
| 1 | 14.86 | 3,911 | 41.82 | 157.5 | 9,609 | 0.407 |
| 20 | 17.36 | 2,204 | 37.80 | 193.1 | 5,545 | 0.397 |
| 40 | 20.29 | 1,325 | 34.03 | 223.8 | 3,196 | 0.415 |
| 50 | 21.53 | 943 | 24.58 | 178.2 | 2,592 | 0.364 |
| 60 | 22.89 | 876 | 21.90 | 171.1 | 2,089 | 0.420 |
| 80 | 25.12 | 909 | 20.72 | 177.4 | 1,505 | 0.604 |
| 100 | 26.50 | 961 | 20.88 | 186.5 | 1,245 | 0.771 |

The ratio never approaches one, at either of the two stands checked, at any of the hundred simulated
ages, and it sits at 0.36 to 0.42 straight through the crash. A hard ceiling at N(H) would therefore
not bind on the pass 32 crash at all. The same conclusion follows independently from the currencies.
Converting the age 40 ceiling of 3,196 trees ha⁻¹ at the trajectory's own quadratic mean diameter of
18.09 cm gives a Reineke stand density index near 1,860 on the engine's basis, against a
Weiskittel and Kuehne maximum in the 650 to 1,300 range and an enforced relative density ceiling of
1.00, so `ops$use.sdimort` binds first by a wide margin everywhere except at top heights near 30 m,
where the two ceilings roughly coincide.

What does differ, and differs by a factor that matters, is the rate. Running Garcia's one-step
recursion forward along the same trajectory, the engine removes 66 stems ha⁻¹ yr⁻¹ at age 20 against
Garcia's 13, 25 against 8 at age 40 and 23 against 5 at age 45, and a free-running Garcia trajectory
seeded at the same age-1 state finishes at 1,160 trees ha⁻¹ at age 100 against the engine's 961. The
engine self-thins substantially faster than the fitted relationship implies through the entire
first half of the rotation, and the divergence is largest exactly where the crash occurs. That, and
not the ceiling, is the quantity a Garcia constraint would have to act on.

## 2. Design options

Four options are set out below. Each is described concretely enough to implement, and each is scored
on three axes, namely what it does at the crash, what it does inside the short-interval calibration
window where the pass 24 through 36 results are already validated, and what it costs in new free
parameters. All four assume a new gate, `ops$use.garcia.selfthin`, defaulting FALSE, so that the
production build stays byte-identical when the flag is unset, which is the established convention
for every lever added since v12.6.

**Option A, hard ceiling on total stem density.** After the `ops$use.sdimort` block and after the
ingrowth bind at line 4248, compute plot top height from the advanced tree list, evaluate
N(H) = 10⁴ (beta H)^(−2 gamma/alpha), and if summed expansion exceeds it, scale every tree's
expansion by the ratio. At the crash this does nothing, since Table 1 shows the ratio peaking at
0.771 at age 100 and sitting near 0.4 through the crash window. Inside the calibration window it also
does essentially nothing at the sources it was fit on, since only 2 of the 2,666 NS and NS_LONG
mortality-bearing pairs, 0.1 percent, have an initial state at or above the fitted ceiling, though it
would clip 5.3 percent of mefia_subp and 6.1 percent of mefia initial states, which is a warning
about the curve rather than a benefit of the option. It costs zero new free parameters beyond the
three already fitted, and roughly fifteen lines. It is a guard rail against a pathological state, not
a fix for the observed one.

**Option B, rate constraint on total density loss.** Each step, carry the start-of-step spacing
S1 = 100/sqrt(N1) and top height H1, compute the Garcia one-step prediction
S2 = [S1^alpha − (beta H1)^gamma + (beta H2)^gamma]^(1/alpha), and floor the post-mortality stem
count at lambda times the implied N2, with lambda a tolerance parameter set at or above one. At the
crash this binds hard, since the engine's removal exceeds the Garcia prediction by a factor of three
to five through ages 20 to 50. Inside the calibration window it also binds hard, and that is the
objection. The engine over-removes relative to Garcia from age 1 onward on this trajectory, so a
floor tight enough to change the crash necessarily perturbs the short-interval predictions that the
pass 36 RMSE and TOST table rests on, at every source and not only at the three the curve was fit
against. It costs one new free parameter, lambda, plus the three fitted ones. It also constrains stem
count only, while the pass 32 pathology is a volume deficit at an unremarkable stem count, so holding
stems without holding volume is a live failure mode rather than a hypothetical one.

**Option C, constrain the self-thinning removal only.** Leave `calc_mortality` untouched and cap
`sdm_mfrac` so that the post-step stem count is not driven below the Garcia one-step prediction. In
code this is one additional term inside the existing `dplyr::mutate` at lines 4219 to 4228, computing
a plot-level `sdm_gfloor` from the joined top height and the pre-sdimort expansion sum and replacing
`sdm_keepi` with `pmax(sdm_keepi, sdm_gfloor / N_pre)`. At the crash this binds, because the crash is
`ops$use.sdimort` behavior by the pass 32 attribution, which pass 34 left standing when it withdrew
the site-ordering inference. Inside the calibration window it is inert wherever relative density sits
below `.sdm_onset`, since `sdm_keepi` is already exactly one there, which is the property that makes
this option materially safer than option B. It preserves base mortality's size differentiation and
touches only the size-neutral removal, which is the term with the mechanical link to volume loss. It
costs zero new free parameters if the floor is the raw Garcia prediction, one if a tolerance is
admitted. This is the option with the best ratio of leverage to regression risk.

**Option D, constrain the ingrowth-release term.** Scale `.rel` at model of record line 3054 so that
predicted recruits cannot carry total stem count above N(H), which is a two-line change inside a
block already structured to take multiplicative gates, exactly as `ops$use.ingrowth.matgate` does
five lines below. Its one genuine merit is that Garcia's N counts every stem regardless of diameter,
so this is the only one of the four options that can see a 3 cm recruit at all, and the 10 cm floor
in the `sdi` definition is otherwise a real blind spot. Against that, it is measurably inert on the
case at hand, since post-crash N/N(H) runs 0.42 to 0.77 and never reaches one, and the maturity gate
adopted in pass 35 already occupies this position with a QMD-based rather than height-based
criterion, so a second gate here risks double-counting a correction that has already been made and
scored. It costs zero new free parameters.

## 3. Extrapolation domain, stated plainly

The curve is fit on three staged sources. The benchmark is thirteen cells. The two sets overlap far
less than the phrase "three of eleven sources" suggests, and one element of the overlap is not what
the diagnostic write-up claims it is.

Counting the pooled pair file by source confirms that eleven of the thirteen staged sources the
extraction attempted contributed any stand pairs at all, and that NB, QC, memat and medev contributed
none, so four benchmark cells have no Garcia fit data of any kind and cannot acquire any without
restaging. Baxter contributed three pairs and none with measurable mortality. PEF contributed four
pairs and three with mortality. Neither is a basis for anything.

The material finding concerns NS. The Garcia extraction read `bench_ns_tree_init.csv` and
`bench_ns_long_tree_init.csv` whole, with no filter on the `MANAGED` column those sources carry, and
the benchmark splits both into managed and unmanaged cells. Counting the pairs files directly,
`bench_ns_pairs.csv` is 2,500 managed against 2,500 unmanaged and `bench_ns_long_pairs.csv` is 3,892
against 4,419. Joining the fitted pair set back to those files, 627 of the 2,987 pairs in the pooled
`nlme` fit, 21 percent, are managed stands. The write-up's scope statement, that the curve is fit
"only for ns, ns_long, and mefia_subp, natural or lightly-managed permanent-sample-plot networks," is
therefore not accurate as written. Roughly a fifth of the fit is managed data, and the pooled curve
carries whatever thinning signal that fifth contains. This is a correction to the record, not an
argument against the curve, yet it means the honest domain statement has to be rebuilt from a
managed-versus-unmanaged refit rather than asserted from the source labels.

One thing that was checked and came back clean is worth recording so it is not re-litigated. The
pass 36 NS subplot-pooling defect does not contaminate the fit. The staged NS files the extraction
read were rewritten on August 26, 2026 at 12:26 and 12:27, before the extraction ran at 16:19, and
recomputing stand basal area directly from `bench_ns_tree_init.csv` gives a maximum of 86.1 m² ha⁻¹
across 5,000 stands with segmented `NS_RS_*P*` keys, against the 1,076 m² ha⁻¹ the defect produced.
The correction was in place when Garcia read the files.

**Table 2.** Standing of each pass 36 benchmark cell relative to the fitted Garcia curve.

| Benchmark cell | Fit data contributed | Could the constraint legitimately bind |
|---|---|---|
| NS unmanaged | yes, part of the 719 unmanaged ns pairs | yes, this is the core domain |
| NS-long unmanaged | yes, part of the 1,320 unmanaged ns_long pairs | yes, this is the core domain |
| NS managed | yes, 468 pairs, inside the pooled fit | contested, in the fit yet outside the paper's stated validity |
| NS-long managed | yes, 159 pairs, inside the pooled fit | contested, same reason |
| MEFIA-L | 57 pairs, dropped, never converged individually | no |
| CTRN | 222 pairs, dropped, converged to alpha 41.7 and gamma 78.3 | no |
| Baxter | 3 pairs, none with mortality | no |
| PEF | 3 mortality-bearing pairs | no |
| SILC-L | 11 mortality-bearing pairs | no |
| NB | none | no |
| QC | none | no |
| memat | none | no |
| medev | none | no |

The options for the ten cells the curve cannot speak for are three, and they are not equally
defensible. Leaving them unconstrained is the honest default and costs nothing, since the constraint
is gated and simply is not switched on, yet it means the lever cannot be evaluated on most of the
benchmark and any adoption claim would rest on two clean cells. Fitting a separate managed-stand
curve is the option Garcia's own paper points at, since he is explicit that thinned stands with
divergent histories admit a limiting plane rather than a shared line, and the 627 managed pairs
already in hand plus CTRN's 222 and SILC's 11 are enough to attempt it, though CTRN's degenerate
individual optimum is a warning that the attempt may fail the same way the six-source hierarchical
fit did. Gating the constraint behind a source or management flag is the option with existing
precedent in this engine, and it is worth naming the precedent precisely. `ops$use.hw.mod` gates a
species-restricted modifier, and v13.3's `ddbh_hw_mod_fia` was deliberately placed behind that
existing flag rather than given a new one. Closer still is `ops$mort.dens.scale` at model of record
lines 4160 to 4172, which already derives a managed status inside the mortality block from
`ops$stand.managed` where supplied and from `ops$mgmt.class` or an active `ops$thin.year` otherwise,
so the engine can already tell a managed stand from a natural one at exactly the point a Garcia
constraint would sit. Reusing that inference costs nothing and is the recommended gating, with the
constraint applying only where the managed inference is false.

## 4. Test plan against the pass 32 crash

**What is being tested.** Not whether the constraint improves the model overall, which no single pass
can establish, but two separable claims. The first is that the constraint prevents the mid-rotation
basal area and volume crash rather than masking it. The second is that it does not disturb the
short-interval behavior already validated in pass 36. Both need pre-declared criteria, and the second
needs the equivalence machinery that pass 36 established, since a lever that shifts short-interval
predictions is disqualified regardless of what it does at long horizon.

**Baseline.** The comparison baseline is h2_matgate, the production default adopted August 26, 2026,
not h1_v132_mortgate. This matters because the maturity gate already repairs the post-crash volume
recovery failure, moving CTRN from 961 trees ha⁻¹, quadratic mean diameter 16.6 cm and 187 m³ ha⁻¹
at age 100 to 383, 27.9 cm and 245 m³ ha⁻¹, against a zero-recruitment bound of 370, 28.2 cm and 242.
Any Garcia constraint must be shown to add something on top of a lever that already reaches the
ingrowth-free ceiling, and testing against the superseded h1 default would manufacture an improvement
that the production build already has.

**The runs.** Four long-horizon arms, using the pass 34 fixed-stand csi ladder rather than the pass 32
four-stand comparison, since pass 34 established that the four-stand statistic cannot separate site
response from stand-to-stand differences in initial density, structure and composition and withdrew
it. Arm one is production, h2_matgate, unchanged. Arm two is production plus the option C constraint
with no tolerance. Arm three is production plus option C with the tolerance parameter at whatever
value the design settles on, included so that a constraint that helps but is mistuned can be
distinguished from one that does not help. Arm four is production with `ops$use.sdimort` switched off
entirely, which is the ceiling probe, the analogue of pass 33's zero-recruitment bound, and it
establishes the maximum any mortality-side intervention can achieve. Six sources at six csi rungs
per arm, following pass 34's design, is 144 tasks, and the anchor-stand rule needs the minimum
initial tree count that pass 34's limitations section already flagged as missing after NB's anchor
came in at six initial trees.

Alongside these, one inertness run. The constraint gated off must reproduce the current production
trajectory byte for byte, checked by MD5 against the existing
`results/p33_ingrowth_gating/` output the way pass 33 checked its own lever. A lever that is not
provably inert when off cannot be shipped gated.

**The diagnostic that distinguishes prevention from masking.** Volume at age 100 is not it, since a
constraint that holds stems without holding volume, or that simply delays the crash past the horizon,
would pass on a terminal figure. Three within-trajectory quantities are needed together. First, the
minimum of standing volume over ages 40 to 70 expressed as a fraction of the trajectory's own age-40
volume, which is the crash depth, currently 178.2 against 223.8 at CTRN, a trough at 0.796. Second,
the trajectory of N/N(H) from Table 1, which under a working constraint should approach the line from
below and then track it rather than falling away from it and drifting back, and which is the
diagnostic that shows whether the model is on the self-thinning trajectory or merely somewhere below
it. Third, and this is the one that catches masking, the ratio of standing volume to basal area
through the crash window, since a constraint that prevents the crash by retaining small stems will
hold basal area while volume per unit basal area falls, and a constraint that prevents it by
retaining the trees that were there will not. Reporting the crash depth alone would miss that
distinction entirely.

**Acceptance criteria, declared in advance.** The long-horizon criterion is that the crash-depth
ratio rises to 0.95 or above at CTRN and at memat, the two sources where the pass 33 work located the
clearest pathology, without falling below its production value at any of the six, and that the
volume-to-basal-area ratio through ages 40 to 70 stays within 5 percent of its production value, so
the volume is held by holding trees rather than by holding stems. The short-interval criterion is the
pass 36 protocol unchanged, meaning every one of the thirteen cells rescored under the constrained
configuration, every point estimate carried with a 5,000 replicate cluster bootstrap under the
per-source cluster rule the scorer already declares, and equivalence decided by bootstrap TOST on the
intercept and slope of observed on predicted with the region of equivalence declared a priori at 25
percent. The equivalence being tested is between the constrained configuration and current production
h2_matgate, not between prediction and observation, since the question is whether the lever moves the
short-interval answer at all. The criterion is that TOST passes on both intercept and slope at every
cell that clears the observed-basis and physical-validity gates, which is currently ten of thirteen,
and that root mean square error does not rise by more than 0.5 percentage points at any cell, which
is the adoption gate passes 33 and 35 used. The two NS unmanaged cells and the two NS-long unmanaged
cells carry additional weight in the reading, since those are the only cells inside the curve's
domain, and a failure there is disqualifying in a way a failure at QC would not be.

**What would falsify the idea.** Four results, any one of which means the constraint should be
abandoned rather than retuned. First, if arm four, `ops$use.sdimort` switched off entirely, does not
repair the crash, then the crash is not a self-thinning-removal phenomenon and no constraint on that
removal can fix it, exactly as pass 33's zero-recruitment probe retired the ingrowth-side work by
showing the residual survived complete removal of the mechanism. Second, if arm two, the untolerated
constraint, is inert on the crash-depth ratio, then the Garcia relation does not bind where the
pathology lives and the whole line closes, and the evidence in section 1 says this is a live
possibility rather than a formality. Third, if the short-interval TOST fails at NS unmanaged or
NS-long unmanaged, the constraint is disturbing the model inside the very domain the curve was fit
on, which is the least defensible place for it to do damage. Fourth, if the volume-to-basal-area
ratio moves by more than 5 percent while the crash depth improves, the constraint is masking the
crash with retained small stems and the improvement is an artifact of the statistic.

A fifth result would not falsify the idea but would change what is being tested, namely a
managed-versus-unmanaged refit that returns materially different coefficients. In that case the
pooled curve is a mixture rather than a population curve and the constraint would have to be
parameterised per management class before any of the above means anything.

## 5. Recommendation, cost and what remains unknown

The recommendation is to do the cheap work first and to hold the engine change behind it, in three
steps rather than one.

Step one is to refit the curve split on `MANAGED` at NS and NS_LONG, and to record whether the
managed and unmanaged coefficients differ beyond their intervals. This is the prerequisite that
section 3 established, it needs no engine change and no long-horizon run, and it costs one session
and under one Cardinal hour, since the pair file is 1.5 MB and the `nlme` fit that produced the
pooled result converged in minutes. If the two classes agree, the domain statement simplifies and the
pooled curve stands with a corrected scope note. If they disagree, the pooled curve is retired in its
current form and the engine question is deferred until there is a curve worth consuming.

Step two is to add the self-thinning relation to `bakuzis_check.R` as a diagnostic, evaluating
N/N(H) along every trajectory the Bakuzis battery already produces and flagging departures. This
costs no engine risk, no new parameters and no new runs beyond rescoring existing trajectory files,
roughly one session and two Cardinal hours. Its value is that it converts the curve from a research
finding into a standing instrument, and the Bakuzis battery currently reports Reineke as
"not in a self-thinning regime, Reineke n/a" at all four CTRN sites, which means the battery has no
working self-thinning test at that source at all. Filling that gap is worth doing whether or not the
engine change ever happens.

Step three, and only if steps one and two both come back supporting it, is option C behind
`ops$use.garcia.selfthin`, gated additionally on the managed inference already computed at model of
record lines 4160 to 4172, tested under the section 4 plan. Realistically that is two to three
sessions and, at the pass 34 array's observed scale of 18 tasks completing comfortably within a
session, roughly 60 to 100 Cardinal hours for the 144-task ladder plus a thirteen-cell rescore
comparable to job 13977045, which ran twelve NS cells in about three hours of wall clock.

The honest reading of the evidence assembled here is that step three is unlikely to be reached on the
current curve. A hard ceiling is measurably inert on the pass 32 crash, the crash is a volume deficit
at 0.36 to 0.42 of the fitted ceiling, and the production default already carries a lever that
repairs the post-crash volume recovery to within the ingrowth-free bound. The Garcia relation's real
contribution to this engine may be diagnostic rather than constraining, and the scoping conclusion
should not be dressed up as anything more than that.

**What could not be verified.** Six items, listed so none is mistaken for established.

The relative density trajectory through the crash window was never measured directly. Neither the
Bakuzis trajectory CSVs nor the standlogs carry a relative density column, so the claim that
`ops$use.sdimort` is active through ages 40 to 55 at CTRN rests on approximating stand density index
as N (QMD/25.4)^1.6 without the 10 cm filter the engine applies, which gives roughly 770 at age 40
against a maximum in the 650 to 1,300 range, hence a relative density near 0.6 to 0.8. That is
consistent with the lever being active and is not proof of it. A one-line addition to the trajectory
builder would settle it.

The decomposition of removal between base mortality and `ops$use.sdimort` through the crash window is
unmeasured. Section 1 establishes that the two differ in size-selectivity, and section 2's preference
for option C over option B depends on the self-thinning term carrying most of the crash-window
removal, which is inferred from the pass 32 attribution rather than measured per year.

The top height definitional mismatch between `calc_topht`, which sorts by height, and the Garcia
extraction, which sorted by diameter, is unquantified. It is expected to be small in even-aged
softwood and larger in irregular structures, and it has not been measured on any source.

Whether `mefia_subp` carries any residual of the pass 36 subplot-pooling defect was not checked. The
NS files were verified clean, and the MEFIA subplot staging was not, its file dating from July 21,
2026, well before the pass 36 work.

The Cardinal hour estimates in this section are extrapolations from observed array sizes and one
observed wall clock, namely job 13977045 at twelve NS cells in about three hours, not from a timed
pilot of the runs proposed here.

Finally, whether a managed-stand Garcia fit is achievable at all is unknown. CTRN's individual
optimum was degenerate at alpha 41.7 and gamma 78.3, and the 627 managed NS pairs have not been fit
on their own. Step one will answer it, and it is the reason step one comes first.

## Files read

Cardinal, model of record and Garcia results, all read-only.
`/users/PUOM0008/crsfaaron/AcadianGY_13.1.r`,
`/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd/results/garcia_selfthin/` in full, including
`2026-08-26_garcia_selfthinning_diagnostic_DRAFT.md`, `2026-08-26_garcia_stand_extraction.R`,
`2026-08-26_garcia_nlme_restricted3.R`, `garcia_nlme_coef_restricted3_2026-08-26.csv`,
`garcia_nlme_report_2026-08-26.txt` and `garcia_stand_pairs_with_fortype_2026-08-26.csv`, plus
`/users/PUOM0008/crsfaaron/magplot/verify/multisrc/bench_ns_tree_init.csv`,
`bench_ns_pairs.csv` and `bench_ns_long_pairs.csv`.

Local workspace.
`repos/fvs-acd/scripts/AcadianGY_13.1_DRAFT.r`, `repos/fvs-acd/results/gydb/README.md` passes 32
through 35, `repos/fvs-acd/results/gydb/p36-data-defects_REVIEW_2026-08-26.md`,
`repos/fvs-acd/results/gydb/p36-readme-section_DRAFT_2026-08-26.md`,
`repos/fvs-acd/results/bakuzis/data/ctrn_h1default_traj.csv` and its check report, and
`_context/handoffs/20260826_session_handoff.md`.

## Correction appended 27 August 2026: Table 1's crash depth was under-sampled

Table 1 above samples the CTRN_AP_80_I2014_2015, site 14.3 trajectory at ages 1, 20, 40, 50, 60, 80,
and 100, and the crash-depth figure quoted in the body text, "178.2 against 223.8, a trough at 0.796,"
is the age-50 value used as a proxy for the minimum over the stated crash window (ages 40 to 55). It
is a proxy, not the true minimum: checking every annual value in the same file
(`results/bakuzis/data/ctrn_h1default_traj.csv`, same stand, same site) finds the true minimum at age
54, VOL 167.3 m³ ha⁻¹, giving a crash depth of 0.748 rather than 0.796. Both numbers come from the
identical source file, so this is a sampling-density artifact in Table 1, not a data or methodology
discrepancy across documents. Age 54 falls inside the window Table 1's own caption already declares
(40 to 55), it is simply a year the ten-and-five-year-step table never printed. The corrected figure,
0.748, is now the one carried in
`results/garcia_selfthin/2026-08-27_bakuzis_nh_diagnostic_results.md`'s narrow crash-pathology
follow-up. This does not change section 4 or 5's conclusions, since 0.748 is a deeper crash than 0.796,
which if anything strengthens rather than weakens the case that the crash is real; it only means the
acceptance-criteria discussion in section 4, which cites the 0.796 figure as the baseline a working
constraint would need to raise to 0.95 or above, should use 0.748 as that baseline if section 4 is ever
acted on. Verification: `/tmp/crash_recheck.R` on Cardinal, output reproduced in the commit message.
